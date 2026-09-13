import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/category_rule.dart';
import '../models/transaction.dart';
import 'drift_database.dart';

/// Accès unique à la base locale. La base locale reste la source de
/// vérité immédiate de l'app, jamais un simple cache en attente du
/// serveur : toute écriture passe par ici en premier, sans dépendance
/// réseau. La synchronisation cloud (Supabase, voir SyncService) est
/// purement additive et pilotée depuis la table `sync_queue` remplie ici.
///
/// Sur mobile (Android/iOS), la vraie base SQLite est gérée par Drift
/// (sqlite3 natif via FFI, voir drift_database.dart).
/// Sur le web, la lecture des SMS n'existe pas dans un navigateur, donc le
/// mode web ne sert qu'à itérer sur l'UI. On utilise alors un stockage
/// 100% en mémoire (perdu au refresh), pour éviter toute la mise en place
/// de Drift/sqlite3.wasm côté web — jamais un vrai cible de l'app.
class AppDatabase {
  AppDatabase._() : _driftDb = kIsWeb ? null : AppDatabaseDrift(_openConnection());

  AppDatabase._withDrift(this._driftDb);

  /// Instance partagée par toute l'app. Mutable pour permettre son
  /// remplacement dans les tests (`AppDatabase.withExecutor(...)`).
  static AppDatabase instance = AppDatabase._();

  /// Construit une instance non-singleton pour les tests, câblée sur
  /// l'exécuteur Drift fourni (typiquement `NativeDatabase.memory()`).
  factory AppDatabase.withExecutor(QueryExecutor executor) =>
      AppDatabase._withDrift(AppDatabaseDrift(executor));

  final AppDatabaseDrift? _driftDb;

  AppDatabaseDrift get _db {
    assert(!kIsWeb, '_db ne doit pas être utilisé sur le web.');
    return _driftDb!;
  }

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'mobile_money_tracker',
        native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
      );

  Future<void> close() async {
    await _driftDb?.close();
  }

  // ---------------------------------------------------------------------
  // Stockage en mémoire (web uniquement)
  // ---------------------------------------------------------------------
  final List<Map<String, Object?>> _memTransactions = [];
  final List<Map<String, Object?>> _memCategoryRules = [];
  int _memCategoryRuleNextId = 1;

  // ---------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------

  /// Insère une transaction. Retourne false sans lever d'erreur si une
  /// transaction avec le même id_transaction_operateur existe déjà.
  /// Crée aussi une entrée `sync_queue` dans la même transaction Drift, de
  /// sorte que "toute écriture locale ⇒ une entrée en attente" soit une
  /// garantie structurelle plutôt qu'une convention.
  Future<bool> insertTransactionIfNew(MoneyTransaction tx) async {
    if (kIsWeb) {
      if (tx.idTransactionOperateur != null) {
        final exists = _memTransactions.any(
          (row) => row['id_transaction_operateur'] == tx.idTransactionOperateur,
        );
        if (exists) return false;
      }
      _memTransactions.add(tx.toMap());
      return true;
    }

    return _db.transaction(() async {
      if (tx.idTransactionOperateur != null) {
        final existing = await (_db.select(_db.transactions)
              ..where((t) => t.idTransactionOperateur.equals(tx.idTransactionOperateur!)))
            .getSingleOrNull();
        if (existing != null) return false;
      }
      await _db.into(_db.transactions).insert(_companionFromModel(tx));
      await _enqueueSync(tx);
      return true;
    });
  }

  Future<void> updateTransaction(MoneyTransaction tx) async {
    tx.derniereModification = DateTime.now();

    if (kIsWeb) {
      final index = _memTransactions.indexWhere((row) => row['id'] == tx.id);
      if (index != -1) {
        _memTransactions[index] = tx.toMap();
      }
      return;
    }

    await _db.transaction(() async {
      await (_db.update(_db.transactions)..where((t) => t.id.equals(tx.id)))
          .write(_companionFromModel(tx));
      await _enqueueSync(tx);
    });
  }

  /// Réassigne [nouvelleCategorie] à toutes les transactions "similaires" à
  /// [tx] (même numéro de contact exact, ou à défaut même nom de contact
  /// exact — hors [tx] elle-même), suite à une correction manuelle de
  /// catégorie. Chaque ligne modifiée passe par le même chemin que
  /// [updateTransaction] (écriture + entrée `sync_queue`), pour que la
  /// garantie "toute écriture locale ⇒ une entrée en attente" reste valable
  /// ici aussi. Retourne le nombre de transactions effectivement modifiées.
  Future<int> reassignSimilarTransactions(MoneyTransaction tx, String nouvelleCategorie) async {
    final numero = tx.contactNumero;
    final nom = tx.contactNom;
    final aUnCritere = (numero != null && numero.isNotEmpty) || (nom != null && nom.isNotEmpty);
    if (!aUnCritere) return 0;

    if (kIsWeb) {
      var count = 0;
      for (final row in _memTransactions) {
        if (row['id'] == tx.id) continue;
        final matches = (numero != null && numero.isNotEmpty)
            ? row['contact_numero'] == numero
            : row['contact_nom'] == nom;
        if (matches && row['categorie'] != nouvelleCategorie) {
          row['categorie'] = nouvelleCategorie;
          row['derniere_modification'] = DateTime.now().toIso8601String();
          count++;
        }
      }
      return count;
    }

    return _db.transaction(() async {
      final query = _db.select(_db.transactions)
        ..where((t) => t.id.equals(tx.id).not());
      if (numero != null && numero.isNotEmpty) {
        query.where((t) => t.contactNumero.equals(numero));
      } else {
        query.where((t) => t.contactNom.equals(nom!));
      }
      final rows = await query.get();

      var count = 0;
      for (final row in rows) {
        if (row.categorie == nouvelleCategorie) continue;
        final similaire = _modelFromRow(row)
          ..categorie = nouvelleCategorie
          ..derniereModification = DateTime.now();
        await (_db.update(_db.transactions)..where((t) => t.id.equals(row.id)))
            .write(_companionFromModel(similaire));
        await _enqueueSync(similaire);
        count++;
      }
      return count;
    });
  }

  Future<List<MoneyTransaction>> getAllTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    if (kIsWeb) {
      final rows = _memTransactions.where((row) {
        final dateStr = row['date_transaction'] as String?;
        if (dateStr == null) return true;
        final date = DateTime.parse(dateStr);
        if (from != null && date.isBefore(from)) return false;
        if (to != null && date.isAfter(to)) return false;
        return true;
      }).toList();
      rows.sort((a, b) => (b['date_transaction'] as String)
          .compareTo(a['date_transaction'] as String));
      return rows.map(MoneyTransaction.fromMap).toList();
    }

    final query = _db.select(_db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.dateTransaction)]);
    if (from != null) {
      query.where((t) => t.dateTransaction.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.dateTransaction.isSmallerOrEqualValue(to));
    }
    final rows = await query.get();
    return rows.map(_modelFromRow).toList();
  }

  Future<int> countTransactions() async {
    if (kIsWeb) return _memTransactions.length;
    final countExp = _db.transactions.id.count();
    final row =
        await (_db.selectOnly(_db.transactions)..addColumns([countExp])).getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<void> deleteAllTransactions() async {
    if (kIsWeb) {
      _memTransactions.clear();
      return;
    }
    await _db.delete(_db.transactions).go();
  }

  // ---------------------------------------------------------------------
  // Règles de catégorisation
  //
  // Volontairement jamais synchronisées vers Supabase (Phase 2) : leur id
  // est un entier auto-incrémenté local sans identité stable entre
  // appareils (contrairement à l'id uuid des transactions), donc un
  // upsert-par-id y corromprait les données en cas d'usage multi-appareil.
  // ---------------------------------------------------------------------

  Future<void> upsertCategoryRule(CategoryRule rule) async {
    if (kIsWeb) {
      final index = _memCategoryRules.indexWhere((row) =>
          row['match_type'] == rule.matchType &&
          row['match_value'] == rule.matchValue);
      if (index != -1) {
        _memCategoryRules[index] = {
          ..._memCategoryRules[index],
          'categorie': rule.categorie,
        };
      } else {
        final map = rule.toMap();
        map['id'] = _memCategoryRuleNextId++;
        _memCategoryRules.add(map);
      }
      return;
    }

    final existing = await (_db.select(_db.categoryRules)
          ..where((r) =>
              r.matchType.equals(rule.matchType) & r.matchValue.equals(rule.matchValue)))
        .getSingleOrNull();
    if (existing != null) {
      await (_db.update(_db.categoryRules)..where((r) => r.id.equals(existing.id)))
          .write(CategoryRulesCompanion(categorie: Value(rule.categorie)));
    } else {
      await _db.into(_db.categoryRules).insert(
            CategoryRulesCompanion.insert(
              matchType: rule.matchType,
              matchValue: rule.matchValue,
              categorie: rule.categorie,
            ),
          );
    }
  }

  Future<List<CategoryRule>> getCategoryRules() async {
    if (kIsWeb) {
      return _memCategoryRules.map(CategoryRule.fromMap).toList();
    }
    final rows = await _db.select(_db.categoryRules).get();
    return rows
        .map((r) => CategoryRule(
              id: r.id,
              matchType: r.matchType,
              matchValue: r.matchValue,
              categorie: r.categorie,
            ))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Synchronisation (Phase 2) — consommé par SyncService, jamais par l'UI
  // directement.
  // ---------------------------------------------------------------------

  Future<void> _enqueueSync(MoneyTransaction tx) async {
    final now = DateTime.now();
    await _db.into(_db.syncQueueEntries).insert(
          SyncQueueEntriesCompanion.insert(
            entityId: tx.id,
            payload: jsonEncode(tx.toMap()),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  /// Entrées prêtes pour un essai de synchronisation : `en_attente`, sans
  /// backoff programmé ou dont le backoff est déjà écoulé.
  Future<List<SyncQueueEntryRow>> getSyncableEntries() {
    final now = DateTime.now();
    return (_db.select(_db.syncQueueEntries)
          ..where((e) =>
              e.status.equals('en_attente') &
              (e.nextAttemptAt.isNull() | e.nextAttemptAt.isSmallerOrEqualValue(now)))
          ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
        .get();
  }

  Stream<List<SyncQueueEntryRow>> watchPendingSyncEntries() {
    return (_db.select(_db.syncQueueEntries)..where((e) => e.status.equals('en_attente')))
        .watch();
  }

  /// Dernier message d'erreur de synchronisation connu, pour diagnostic sur
  /// l'écran de connexion. `null` si aucune entrée n'a jamais échoué.
  Future<String?> getLastSyncError() async {
    if (kIsWeb) return null;
    final row = await (_db.select(_db.syncQueueEntries)
          ..where((e) => e.lastError.isNotNull())
          ..orderBy([(e) => OrderingTerm.desc(e.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.lastError;
  }

  Future<bool> hasFailedSyncEntries() async {
    final countExp = _db.syncQueueEntries.id.count();
    final row = await (_db.selectOnly(_db.syncQueueEntries)
          ..addColumns([countExp])
          ..where(_db.syncQueueEntries.status.equals('echec')))
        .getSingle();
    return (row.read(countExp) ?? 0) > 0;
  }

  Stream<int> watchPendingSyncCount() {
    final countExp = _db.syncQueueEntries.id.count();
    final query = _db.selectOnly(_db.syncQueueEntries)
      ..addColumns([countExp])
      ..where(_db.syncQueueEntries.status.equals('en_attente'));
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  Future<void> markSyncEntry(
    int id, {
    required String status,
    int? attemptCount,
    DateTime? nextAttemptAt,
    String? lastError,
  }) {
    return (_db.update(_db.syncQueueEntries)..where((e) => e.id.equals(id))).write(
      SyncQueueEntriesCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
        attemptCount: attemptCount != null ? Value(attemptCount) : const Value.absent(),
        nextAttemptAt: Value(nextAttemptAt),
        lastError: Value(lastError),
      ),
    );
  }

  /// Réarme immédiatement toute entrée non synchronisée — `en_attente` (y
  /// compris celles dont le backoff n'a pas encore expiré) ou `echec` —
  /// pour un réessai manuel explicite (bouton "Réessayer maintenant" de
  /// l'écran de connexion), qui ne doit pas attendre le prochain palier de
  /// backoff comme le ferait une reconnexion automatique.
  Future<void> forceRetryAllPending() {
    return (_db.update(_db.syncQueueEntries)
          ..where((e) => e.status.equals('en_attente') | e.status.equals('echec')))
        .write(
      SyncQueueEntriesCompanion(
        status: const Value('en_attente'),
        attemptCount: const Value(0),
        nextAttemptAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Redonne une chance aux entrées en échec à la reconnexion (jeton
  /// expiré, coupure transitoire...).
  Future<void> resetFailedEntriesToPending() {
    return (_db.update(_db.syncQueueEntries)..where((e) => e.status.equals('echec'))).write(
      SyncQueueEntriesCompanion(
        status: const Value('en_attente'),
        attemptCount: const Value(0),
        nextAttemptAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Applique côté local une ligne reçue du serveur (le serveur fait
  /// autorité : soit elle est nouvelle localement, soit elle a déjà gagné
  /// le conflit last-write-wins). N'écrase jamais un enregistrement local
  /// strictement plus récent (une pull tardive ne doit jamais effacer une
  /// édition locale pas encore poussée).
  Future<void> applyRemoteTransaction(MoneyTransaction remote) async {
    if (kIsWeb) return;
    final local = await (_db.select(_db.transactions)..where((t) => t.id.equals(remote.id)))
        .getSingleOrNull();
    if (local != null && !remote.derniereModification.isAfter(local.derniereModification)) {
      return;
    }
    await _db.into(_db.transactions).insertOnConflictUpdate(_companionFromModel(remote));
  }

  Future<void> recordConflict(
    String transactionId,
    Map<String, Object?> localVersion,
    Map<String, Object?> remoteVersion,
  ) {
    return _db.into(_db.conflictHistoryEntries).insert(
          ConflictHistoryEntriesCompanion.insert(
            transactionId: transactionId,
            localVersionJson: jsonEncode(localVersion),
            remoteVersionJson: jsonEncode(remoteVersion),
            detectedAt: DateTime.now(),
          ),
        );
  }

  Future<DateTime> getLastPulledAt() async {
    final row =
        await (_db.select(_db.syncMetaTable)..where((m) => m.id.equals(0))).getSingle();
    return row.lastPulledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> setLastPulledAt(DateTime value) {
    return (_db.update(_db.syncMetaTable)..where((m) => m.id.equals(0)))
        .write(SyncMetaTableCompanion(lastPulledAt: Value(value)));
  }

  // ---------------------------------------------------------------------
  // Conversion MoneyTransaction <-> ligne Drift
  // ---------------------------------------------------------------------

  TransactionsCompanion _companionFromModel(MoneyTransaction tx) => TransactionsCompanion(
        id: Value(tx.id),
        source: Value(sourceToString(tx.source)),
        type: Value(typeToString(tx.type)),
        montant: Value(tx.montant),
        frais: Value(tx.frais),
        montantNet: Value(tx.montantNet),
        soldeApres: Value(tx.soldeApres),
        contactNom: Value(tx.contactNom),
        contactNumero: Value(tx.contactNumero),
        categorie: Value(tx.categorie),
        dateTransaction: Value(tx.dateTransaction),
        idTransactionOperateur: Value(tx.idTransactionOperateur),
        smsBrut: Value(tx.smsBrut),
        notes: Value(tx.notes),
        statutEdition:
            Value(tx.statutEdition == EditStatus.auto ? 'auto' : 'edite_manuellement'),
        derniereModification: Value(tx.derniereModification),
      );

  MoneyTransaction _modelFromRow(TransactionRow row) => MoneyTransaction(
        id: row.id,
        source: sourceFromString(row.source),
        type: typeFromString(row.type),
        montant: row.montant,
        frais: row.frais,
        montantNet: row.montantNet,
        soldeApres: row.soldeApres,
        contactNom: row.contactNom,
        contactNumero: row.contactNumero,
        categorie: row.categorie,
        dateTransaction: row.dateTransaction,
        idTransactionOperateur: row.idTransactionOperateur,
        smsBrut: row.smsBrut,
        notes: row.notes,
        statutEdition: row.statutEdition == 'edite_manuellement'
            ? EditStatus.editeManuellement
            : EditStatus.auto,
        derniereModification: row.derniereModification,
      );
}
