import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/category_rule.dart';
import '../models/transaction.dart';
import '../services/sync_transport.dart' show SyncCursor, SyncEntity;
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
  final List<String> _memCategories = List.of(categoriesParDefaut);

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
      return _reassignerCategoriePourLignes(rows, nouvelleCategorie);
    });
  }

  /// Réassigne [nouvelleCategorie] à un ensemble de transactions choisies
  /// manuellement par l'utilisateur (sélection multiple dans la liste),
  /// par opposition à [reassignSimilarTransactions] qui déduit la
  /// similarité automatiquement. Retourne le nombre de transactions
  /// effectivement modifiées.
  Future<int> bulkSetCategory(List<String> ids, String nouvelleCategorie) async {
    if (ids.isEmpty) return 0;

    if (kIsWeb) {
      var count = 0;
      for (final row in _memTransactions) {
        if (ids.contains(row['id']) && row['categorie'] != nouvelleCategorie) {
          row['categorie'] = nouvelleCategorie;
          row['derniere_modification'] = DateTime.now().toIso8601String();
          count++;
        }
      }
      return count;
    }

    return _db.transaction(() async {
      final rows =
          await (_db.select(_db.transactions)..where((t) => t.id.isIn(ids))).get();
      return _reassignerCategoriePourLignes(rows, nouvelleCategorie);
    });
  }

  /// Applique [nouvelleCategorie] à chaque ligne (hors web), en passant par
  /// le même chemin que [updateTransaction] (écriture + entrée
  /// `sync_queue`). Facteur commun de [reassignSimilarTransactions] et
  /// [bulkSetCategory].
  Future<int> _reassignerCategoriePourLignes(
    List<TransactionRow> rows,
    String nouvelleCategorie,
  ) async {
    var count = 0;
    for (final row in rows) {
      if (row.categorie == nouvelleCategorie) continue;
      final modifiee = _modelFromRow(row)
        ..categorie = nouvelleCategorie
        ..derniereModification = DateTime.now();
      await (_db.update(_db.transactions)..where((t) => t.id.equals(row.id)))
          .write(_companionFromModel(modifiee));
      await _enqueueSync(modifiee);
      count++;
    }
    return count;
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

  /// Version réactive de [getAllTransactions] : notifie chaque nouvel
  /// événement (ajout manuel, SMS détecté, catégorie modifiée) sans que
  /// l'écran appelant ait à recharger explicitement.
  Stream<List<MoneyTransaction>> watchTransactions({
    DateTime? from,
    DateTime? to,
  }) {
    if (kIsWeb) {
      // Pas de vrai stream réactif en mémoire, voir watchCategories().
      final rows = _memTransactions.where((row) {
        final dateStr = row['date_transaction'] as String?;
        if (dateStr == null) return true;
        final date = DateTime.parse(dateStr);
        if (from != null && date.isBefore(from)) return false;
        if (to != null && date.isAfter(to)) return false;
        return true;
      }).toList()
        ..sort((a, b) => (b['date_transaction'] as String)
            .compareTo(a['date_transaction'] as String));
      return Stream.value(rows.map(MoneyTransaction.fromMap).toList());
    }

    final query = _db.select(_db.transactions)
      ..orderBy([(t) => OrderingTerm.desc(t.dateTransaction)]);
    if (from != null) {
      query.where((t) => t.dateTransaction.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.dateTransaction.isSmallerOrEqualValue(to));
    }
    return query.watch().map((rows) => rows.map(_modelFromRow).toList());
  }

  Future<int> countTransactions() async {
    if (kIsWeb) return _memTransactions.length;
    final countExp = _db.transactions.id.count();
    final row =
        await (_db.selectOnly(_db.transactions)..addColumns([countExp])).getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Supprime une transaction et met en file sa pierre tombale, pour que
  /// la suppression atteigne Supabase puis les autres appareils.
  Future<void> deleteTransaction(String id) async {
    if (kIsWeb) {
      _memTransactions.removeWhere((row) => row['id'] == id);
      return;
    }
    await _db.transaction(() async {
      final row = await (_db.select(_db.transactions)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row == null) return;
      await _supprimerAvecPierreTombale(row);
    });
  }

  Future<void> deleteAllTransactions() async {
    if (kIsWeb) {
      _memTransactions.clear();
      return;
    }
    await _db.transaction(() async {
      for (final row in await _db.select(_db.transactions).get()) {
        await _supprimerAvecPierreTombale(row);
      }
    });
  }

  Future<void> _supprimerAvecPierreTombale(TransactionRow row) async {
    final tombe = _modelFromRow(row)..derniereModification = DateTime.now();
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(row.id))).go();
    await _enqueue(
      SyncEntity.transaction,
      row.id,
      {...tombe.toMap(), 'supprime': true},
      operation: 'delete',
    );
  }

  // ---------------------------------------------------------------------
  // Règles de catégorisation
  //
  // Synchronisées sous l'identité (matchType, matchValue), voir [ruleKey] :
  // l'id auto-incrémenté local n'a aucune identité stable entre appareils.
  // ---------------------------------------------------------------------

  /// Clé de synchronisation d'une règle (colonne `cle` côté Supabase).
  static String ruleKey(String matchType, String matchValue) => '$matchType:$matchValue';

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

    await _db.transaction(() async {
      final existing = await (_db.select(_db.categoryRules)
            ..where((r) =>
                r.matchType.equals(rule.matchType) & r.matchValue.equals(rule.matchValue)))
          .getSingleOrNull();
      if (existing != null && existing.categorie == rule.categorie) return;
      final now = DateTime.now();
      if (existing != null) {
        await (_db.update(_db.categoryRules)..where((r) => r.id.equals(existing.id))).write(
            CategoryRulesCompanion(
                categorie: Value(rule.categorie), derniereModification: Value(now)));
      } else {
        await _db.into(_db.categoryRules).insert(
              CategoryRulesCompanion.insert(
                matchType: rule.matchType,
                matchValue: rule.matchValue,
                categorie: rule.categorie,
                derniereModification: Value(now),
              ),
            );
      }
      await _enqueue(SyncEntity.categoryRule, ruleKey(rule.matchType, rule.matchValue), {
        'match_type': rule.matchType,
        'match_value': rule.matchValue,
        'categorie': rule.categorie,
        'supprime': false,
        'derniere_modification': now.toIso8601String(),
      });
    });
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

  /// Noms de contact distincts sur l'ensemble des transactions (triés),
  /// pour l'écran Réglages > Contacts qui permet d'associer un contact à
  /// une catégorie une bonne fois pour toutes.
  Future<List<String>> getUniqueContactNames() async {
    final transactions = await getAllTransactions();
    final noms = transactions
        .map((t) => t.contactNom?.trim())
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return noms;
  }

  /// Associe un contact (nom exact) à une catégorie : mémorise la règle
  /// pour la catégorisation automatique des futures transactions de ce
  /// contact (voir CategorizationService.suggestCategory) ET réassigne
  /// immédiatement toutes ses transactions déjà existantes. Retourne le
  /// nombre de transactions existantes modifiées.
  Future<int> associateContactWithCategory(String nom, String categorie) async {
    await upsertCategoryRule(CategoryRule(
      matchType: 'contact_nom_contains',
      matchValue: nom,
      categorie: categorie,
    ));

    if (kIsWeb) {
      final ids = _memTransactions
          .where((row) => row['contact_nom'] == nom)
          .map((row) => row['id'] as String)
          .toList();
      return bulkSetCategory(ids, categorie);
    }

    final rows =
        await (_db.select(_db.transactions)..where((t) => t.contactNom.equals(nom))).get();
    return bulkSetCategory(rows.map((r) => r.id).toList(), categorie);
  }

  // ---------------------------------------------------------------------
  // Catégories (écran Réglages) — synchronisées sous l'identité
  // `lower(nom)`, voir [categoryKey]. Les catégories par défaut, seedées
  // sur chaque appareil, ne sont poussées que si on les supprime.
  // ---------------------------------------------------------------------

  /// Clé de synchronisation d'une catégorie (colonne `cle` côté Supabase).
  static String categoryKey(String nom) => nom.toLowerCase();

  /// Catégorie locale de même clé que [nom]. Comparée en Dart : LOWER() de
  /// SQLite ne met en minuscule que l'ASCII, "Électricité" n'y égalerait
  /// donc jamais "électricité".
  Future<CategoryRow?> _categorieParCle(String nom) async {
    final cle = categoryKey(nom);
    final toutes = await _db.select(_db.categories).get();
    return toutes.where((c) => categoryKey(c.nom) == cle).firstOrNull;
  }

  Stream<List<String>> watchCategories() {
    if (kIsWeb) {
      // Pas de vrai stream réactif en mémoire : un seul instantané, suffisant
      // pour l'usage web (itération UI uniquement, voir commentaire en tête
      // de fichier).
      return Stream.value(List.unmodifiable(_memCategories));
    }
    return (_db.select(_db.categories)..orderBy([(c) => OrderingTerm.asc(c.nom)]))
        .watch()
        .map((rows) => rows.map((r) => r.nom).toList());
  }

  /// Ajoute une catégorie si elle n'existe pas déjà (comparaison insensible
  /// à la casse). Ne lève pas d'erreur en cas de doublon : silencieusement
  /// ignoré, pour que l'écran de gestion reste simple (pas de validation
  /// réseau-like à afficher).
  Future<void> addCategory(String nom) async {
    final valeur = nom.trim();
    if (valeur.isEmpty) return;

    if (kIsWeb) {
      final existe = _memCategories.any((c) => c.toLowerCase() == valeur.toLowerCase());
      if (!existe) _memCategories.add(valeur);
      return;
    }

    await _db.transaction(() async {
      if (await _categorieParCle(valeur) != null) return;
      final now = DateTime.now();
      await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(nom: valeur, derniereModification: Value(now)));
      await _enqueue(SyncEntity.category, categoryKey(valeur), {
        'nom': valeur,
        'supprime': false,
        'derniere_modification': now.toIso8601String(),
      });
    });
  }

  Future<void> removeCategory(String nom) async {
    if (kIsWeb) {
      _memCategories.removeWhere((c) => c == nom);
      return;
    }
    await _db.transaction(() async {
      final supprimees =
          await (_db.delete(_db.categories)..where((c) => c.nom.equals(nom))).go();
      if (supprimees == 0) return;
      await _enqueue(
        SyncEntity.category,
        categoryKey(nom),
        {
          'nom': nom,
          'supprime': true,
          'derniere_modification': DateTime.now().toIso8601String(),
        },
        operation: 'delete',
      );
    });
  }

  // ---------------------------------------------------------------------
  // Synchronisation (Phase 2) — consommé par SyncService, jamais par l'UI
  // directement.
  // ---------------------------------------------------------------------

  Future<void> _enqueueSync(MoneyTransaction tx) =>
      _enqueue(SyncEntity.transaction, tx.id, tx.toMap());

  Future<void> _enqueue(
    SyncEntity entity,
    String entityId,
    Map<String, Object?> payload, {
    String operation = 'upsert',
  }) async {
    final now = DateTime.now();
    await _db.into(_db.syncQueueEntries).insert(
          SyncQueueEntriesCompanion.insert(
            entityType: Value(entity.key),
            entityId: entityId,
            operation: Value(operation),
            payload: jsonEncode(payload),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  /// Vrai si une suppression locale de cette entité attend encore d'être
  /// poussée : un pull ne doit alors pas la ressusciter avant que le
  /// serveur ait tranché (last-write-wins) sur la pierre tombale.
  Future<bool> _suppressionEnAttente(SyncEntity entity, String entityId) async {
    final row = await (_db.select(_db.syncQueueEntries)
          ..where((e) =>
              e.entityType.equals(entity.key) &
              e.entityId.equals(entityId) &
              e.operation.equals('delete') &
              e.status.isIn(const ['en_attente', 'echec']))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
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
  ///
  /// [supprime] : la ligne serveur est une pierre tombale — la transaction
  /// locale correspondante est alors supprimée (si elle n'est pas plus
  /// récente).
  Future<void> applyRemoteTransaction(MoneyTransaction remote, {bool supprime = false}) async {
    if (kIsWeb) return;
    await _db.transaction(() async {
      var local = await (_db.select(_db.transactions)..where((t) => t.id.equals(remote.id)))
          .getSingleOrNull();
      if (local == null && await _suppressionEnAttente(SyncEntity.transaction, remote.id)) {
        return;
      }
      // Même transaction opérateur déjà présente localement sous un autre
      // uuid (ex. rescan SMS après réinstallation) : on adopte l'id serveur
      // plutôt que de violer l'index unique local sur
      // id_transaction_operateur.
      if (local == null && remote.idTransactionOperateur != null) {
        local = await (_db.select(_db.transactions)
              ..where((t) => t.idTransactionOperateur.equals(remote.idTransactionOperateur!)))
            .getSingleOrNull();
        if (local != null) await reassignTransactionId(local.id, remote.id);
      }
      if (local != null && !remote.derniereModification.isAfter(local.derniereModification)) {
        return;
      }
      if (supprime) {
        await (_db.delete(_db.transactions)..where((t) => t.id.equals(remote.id))).go();
        return;
      }
      await _db.into(_db.transactions).insertOnConflictUpdate(_companionFromModel(remote));
    });
  }

  /// Applique une ligne serveur de la table `categories` (même règles que
  /// [applyRemoteTransaction] : jamais d'écrasement d'une version locale
  /// plus récente, jamais de résurrection d'une suppression en attente).
  Future<void> applyRemoteCategory(Map<String, Object?> row) async {
    if (kIsWeb) return;
    final nom = row['nom'] as String;
    final cle = categoryKey(nom);
    final ts = DateTime.parse(row['derniere_modification'] as String);
    await _db.transaction(() async {
      final local = await _categorieParCle(nom);
      if (local == null && await _suppressionEnAttente(SyncEntity.category, cle)) return;
      if (local != null && !ts.isAfter(local.derniereModification)) return;
      if (row['supprime'] == true) {
        if (local != null) {
          await (_db.delete(_db.categories)..where((c) => c.id.equals(local.id))).go();
        }
      } else if (local != null) {
        await (_db.update(_db.categories)..where((c) => c.id.equals(local.id))).write(
            CategoriesCompanion(nom: Value(nom), derniereModification: Value(ts)));
      } else {
        await _db.into(_db.categories).insert(
            CategoriesCompanion.insert(nom: nom, derniereModification: Value(ts)));
      }
    });
  }

  /// Applique une ligne serveur de la table `category_rules`.
  Future<void> applyRemoteCategoryRule(Map<String, Object?> row) async {
    if (kIsWeb) return;
    final matchType = row['match_type'] as String;
    final matchValue = row['match_value'] as String;
    final ts = DateTime.parse(row['derniere_modification'] as String);
    await _db.transaction(() async {
      final local = await (_db.select(_db.categoryRules)
            ..where((r) => r.matchType.equals(matchType) & r.matchValue.equals(matchValue)))
          .getSingleOrNull();
      if (local == null &&
          await _suppressionEnAttente(SyncEntity.categoryRule, ruleKey(matchType, matchValue))) {
        return;
      }
      if (local != null && !ts.isAfter(local.derniereModification)) return;
      if (row['supprime'] == true) {
        if (local != null) {
          await (_db.delete(_db.categoryRules)..where((r) => r.id.equals(local.id))).go();
        }
      } else if (local != null) {
        await (_db.update(_db.categoryRules)..where((r) => r.id.equals(local.id))).write(
            CategoryRulesCompanion(
                categorie: Value(row['categorie'] as String), derniereModification: Value(ts)));
      } else {
        await _db.into(_db.categoryRules).insert(CategoryRulesCompanion.insert(
              matchType: matchType,
              matchValue: matchValue,
              categorie: row['categorie'] as String,
              derniereModification: Value(ts),
            ));
      }
    });
  }

  /// Remplace l'uuid local [oldId] d'une transaction par l'uuid [newId]
  /// que le serveur lui connaît déjà (même id_transaction_operateur), en
  /// réécrivant aussi les entrées `sync_queue` qui la référencent pour que
  /// les prochains push ciblent la bonne ligne serveur.
  Future<void> reassignTransactionId(String oldId, String newId) async {
    if (kIsWeb || oldId == newId) return;
    await _db.transaction(() async {
      await (_db.update(_db.transactions)..where((t) => t.id.equals(oldId)))
          .write(TransactionsCompanion(id: Value(newId)));
      final entries = await (_db.select(_db.syncQueueEntries)
            ..where((e) =>
                e.entityType.equals(SyncEntity.transaction.key) & e.entityId.equals(oldId)))
          .get();
      for (final entry in entries) {
        final payload = jsonDecode(entry.payload) as Map<String, Object?>;
        payload['id'] = newId;
        await (_db.update(_db.syncQueueEntries)..where((e) => e.id.equals(entry.id))).write(
          SyncQueueEntriesCompanion(
            entityId: Value(newId),
            payload: Value(jsonEncode(payload)),
          ),
        );
      }
    });
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

  /// Curseur de pull de [entity], null tant que rien n'a été tiré.
  Future<SyncCursor?> getSyncCursor(SyncEntity entity) async {
    final row = await (_db.select(_db.syncCursors)
          ..where((c) => c.entityType.equals(entity.key)))
        .getSingleOrNull();
    return row == null ? null : SyncCursor(row.syncedAt, row.cle);
  }

  Future<void> setSyncCursor(SyncEntity entity, SyncCursor cursor) {
    return _db.into(_db.syncCursors).insertOnConflictUpdate(SyncCursorsCompanion.insert(
          entityType: entity.key,
          syncedAt: cursor.syncedAt,
          cle: cursor.cle,
        ));
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
