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

  /// Plafond de durée d'un appel réseau : sans lui, une requête qui ne
  /// répond jamais laisserait [_running] à true indéfiniment et tout
  /// déclencheur ultérieur (y compris "Réessayer") deviendrait sans effet.
  static const networkTimeout = Duration(seconds: 20);

  StreamSubscription<bool>? _connSub;
  StreamSubscription<List<SyncQueueEntryRow>>? _queueSub;
  bool _running = false;
  bool _rerunRequested = false;
  Completer<void>? _idle;

  void start() {
    if (kIsWeb) return;
    try {
      _connSub = connectivity.onStatusChange.listen((online) {
        if (online) {
          unawaited(db.resetFailedEntriesToPending());
          unawaited(_kick());
        }
      }, onError: (_) {});
    } catch (_) {
      // Un plugin de connectivité indisponible (ex. environnement de test
      // sans canal de plateforme) ne doit jamais empêcher l'app de
      // démarrer : la synchro restera simplement inactive.
    }
    _queueSub = db.watchPendingSyncEntries().listen((entries) {
      if (entries.isNotEmpty) unawaited(_kick());
    });
    unawaited(_kick());
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
  /// file). Se termine une fois le cycle achevé, pour que l'UI puisse
  /// afficher son résultat.
  Future<void> retryNow() async {
    await db.forceRetryAllPending();
    await _kick();
  }

  /// Lance un cycle (ou en redemande un si un cycle est déjà en cours).
  /// Le Future retourné se termine quand plus aucun cycle n'est en cours.
  Future<void> _kick() {
    if (_running) {
      _rerunRequested = true;
      return _idle!.future;
    }
    _running = true;
    final idle = _idle = Completer<void>();
    unawaited(() async {
      do {
        _rerunRequested = false;
        await _runOnce();
      } while (_rerunRequested);
      _running = false;
      idle.complete();
    }());
    return idle.future;
  }

  Future<void> _runOnce() async {
    try {
      final online = await connectivity.checkNow().timeout(networkTimeout);
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
      final entity = SyncEntity.fromKey(entry.entityType);
      final localPayload = jsonDecode(entry.payload) as Map<String, Object?>;
      final serverRow = await transport.push(entity, localPayload).timeout(networkTimeout);
      if (entity == SyncEntity.transaction) {
        // Le serveur connaissait déjà cette transaction opérateur sous un
        // autre uuid (voir sync_upsert_transaction) : on s'aligne sur son id.
        final serverId = serverRow['id'] as String? ?? entry.entityId;
        if (serverId != entry.entityId) {
          await db.reassignTransactionId(entry.entityId, serverId);
        }
      }
      // Marquée avant d'appliquer la ligne serveur : une pierre tombale
      // encore "en attente" empêcherait applyRemote* de restaurer une
      // version serveur plus récente qui a gagné le conflit.
      await db.markSyncEntry(entry.id, status: 'synchronise');
      final localTs = DateTime.parse(localPayload['derniere_modification'] as String);
      final serverTsRaw = serverRow['derniere_modification'];
      if (serverTsRaw != null && DateTime.parse(serverTsRaw as String).isAfter(localTs)) {
        if (entity == SyncEntity.transaction) {
          await db.recordConflict(serverRow['id'] as String, localPayload, serverRow);
        }
        await _appliquer(entity, serverRow);
      }
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

  Future<void> _appliquer(SyncEntity entity, Map<String, Object?> row) {
    switch (entity) {
      case SyncEntity.transaction:
        return db.applyRemoteTransaction(
          MoneyTransaction.fromMap(row),
          supprime: row['supprime'] == true,
        );
      case SyncEntity.category:
        return db.applyRemoteCategory(row);
      case SyncEntity.categoryRule:
        return db.applyRemoteCategoryRule(row);
    }
  }

  /// Tire, page par page, toutes les lignes écrites côté serveur depuis le
  /// curseur de chaque entité. Le curseur est sauvegardé après chaque page
  /// appliquée : une coupure en cours de route reprend où elle s'est
  /// arrêtée.
  Future<void> _pull() async {
    for (final entity in SyncEntity.values) {
      var cursor = await db.getSyncCursor(entity);
      while (true) {
        final rows = await transport.pullPage(entity, cursor).timeout(networkTimeout);
        for (final row in rows) {
          await _appliquer(entity, row);
        }
        if (rows.isEmpty) break;
        final last = rows.last;
        cursor = SyncCursor(
          DateTime.parse(last['synced_at'] as String).toUtc().toIso8601String(),
          '${last[entity.keyColumn]}',
        );
        await db.setSyncCursor(entity, cursor);
        if (rows.length < SyncTransport.pageSize) break;
      }
    }
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
