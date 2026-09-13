import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../db/drift_database.dart';
import '../models/transaction.dart';
import 'connectivity_service.dart';
import 'sync_transport.dart';

enum SyncStatus { synchronise, enAttente, erreur }

/// Fabrique du [SyncService] utilisé par l'app, remplaçable dans les tests
/// (même principe que [AuthGate.current]) pour éviter que les tests widgets
/// ne déclenchent les vrais plugins réseau (connectivity_plus, Supabase).
class SyncServiceFactory {
  static SyncService Function(AppDatabase db) builder = (db) => SyncService(
        db: db,
        connectivity: ConnectivityPlusChecker(),
        transport: SupabaseSyncTransport(),
      );
}

/// Délai de retry en cas d'échec réessayable (réseau, timeout, 5xx) :
/// 2s, 4s, 8s... plafonné à 300s. Les échecs réessayables ne sont JAMAIS
/// abandonnés définitivement — abandonner violerait la garantie "la base
/// locale est la source de vérité" : l'écriture locale reste valide et
/// finira par se synchroniser dès que possible.
Duration computeSyncBackoff(int attemptCount) {
  final seconds = math.min(2 * math.pow(2, attemptCount).toInt(), 300);
  return Duration(seconds: seconds);
}

/// Worker de synchronisation en arrière-plan. Ne bloque jamais l'UI :
/// déclenché de façon réactive par les changements de connectivité (écoutés
/// en continu, pas seulement au lancement) et par l'apparition de
/// nouvelles entrées dans `sync_queue`. Toutes les lectures/écritures de
/// l'app passent par [AppDatabase] uniquement ; la synchronisation est
/// purement additive et se déroule entièrement en tâche de fond.
class SyncService {
  SyncService({
    required this.db,
    required this.connectivity,
    required this.transport,
  });

  final AppDatabase db;
  final ConnectivityChecker connectivity;
  final SyncTransport transport;

  final ValueNotifier<SyncStatus> status = ValueNotifier(SyncStatus.synchronise);

  StreamSubscription<bool>? _connSub;
  StreamSubscription<List<SyncQueueEntryRow>>? _queueSub;
  bool _running = false;
  bool _rerunRequested = false;

  void start() {
    if (kIsWeb) return;
    try {
      _connSub = connectivity.onStatusChange.listen((online) {
        if (online) {
          unawaited(db.resetFailedEntriesToPending());
          _kick();
        }
      }, onError: (_) {});
    } catch (_) {
      // Un plugin de connectivité indisponible (ex. environnement de test
      // sans canal de plateforme) ne doit jamais empêcher l'app de
      // démarrer : la synchro restera simplement inactive.
    }
    _queueSub = db.watchPendingSyncEntries().listen((entries) {
      if (entries.isNotEmpty) _kick();
    });
    _kick();
  }

  void stop() {
    _connSub?.cancel();
    _queueSub?.cancel();
  }

  /// Force une tentative de synchronisation immédiate (ex. bouton
  /// "Réessayer" de l'écran de connexion) : réarme toute entrée non
  /// synchronisée (backoff remis à zéro, y compris pour celles encore en
  /// attente de leur prochain palier) puis relance un cycle, sans attendre
  /// le prochain déclencheur réactif (reconnexion, nouvelle entrée en
  /// file).
  Future<void> retryNow() async {
    await db.forceRetryAllPending();
    _kick();
  }

  void _kick() {
    if (_running) {
      _rerunRequested = true;
      return;
    }
    _running = true;
    unawaited(_runOnce().whenComplete(() {
      _running = false;
      if (_rerunRequested) {
        _rerunRequested = false;
        _kick();
      }
    }));
  }

  Future<void> _runOnce() async {
    try {
      final online = await connectivity.checkNow();
      if (!online) {
        await _refreshStatus(forcedOffline: true);
        return;
      }
      for (final entry in await db.getSyncableEntries()) {
        await _syncOne(entry);
      }
      await _pull();
    } catch (_) {
      // Une erreur inattendue pendant le cycle (y compris une vérification
      // de connectivité indisponible) ne doit jamais remonter : le
      // prochain déclencheur (reconnexion, nouvelle entrée) réessaiera.
    }
    await _refreshStatus();
  }

  Future<void> _syncOne(SyncQueueEntryRow entry) async {
    try {
      final localPayload = jsonDecode(entry.payload) as Map<String, Object?>;
      final serverRow = await transport.pushTransaction(localPayload);
      final localTs = DateTime.parse(localPayload['derniere_modification'] as String);
      final serverTsRaw = serverRow['derniere_modification'];
      if (serverTsRaw != null && DateTime.parse(serverTsRaw as String).isAfter(localTs)) {
        await db.recordConflict(entry.entityId, localPayload, serverRow);
        await db.applyRemoteTransaction(MoneyTransaction.fromMap(serverRow));
      }
      await db.markSyncEntry(entry.id, status: 'synchronise');
    } on NonRetryableSyncException catch (e) {
      await db.markSyncEntry(entry.id, status: 'echec', lastError: e.toString());
    } catch (e) {
      final attempt = entry.attemptCount + 1;
      await db.markSyncEntry(
        entry.id,
        status: 'en_attente',
        attemptCount: attempt,
        nextAttemptAt: DateTime.now().add(computeSyncBackoff(attempt)),
        lastError: e.toString(),
      );
    }
  }

  Future<void> _pull() async {
    final since = await db.getLastPulledAt();
    final rows = await transport.pullChangedSince(since);
    for (final row in rows) {
      await db.applyRemoteTransaction(MoneyTransaction.fromMap(row));
    }
    await db.setLastPulledAt(DateTime.now());
  }

  Future<void> _refreshStatus({bool forcedOffline = false}) async {
    final pendingCount = (await db.getSyncableEntries()).length;
    final hasErrors = await db.hasFailedSyncEntries();
    if (hasErrors) {
      status.value = SyncStatus.erreur;
    } else if (forcedOffline || pendingCount > 0) {
      status.value = SyncStatus.enAttente;
    } else {
      status.value = SyncStatus.synchronise;
    }
  }
}
