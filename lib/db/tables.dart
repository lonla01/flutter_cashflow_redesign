import 'package:drift/drift.dart';

/// Schéma Drift local. Les colonnes de [Transactions] et [CategoryRules]
/// reprennent 1:1 le schéma sqflite de la Phase 1. Les tables suivantes sont
/// nouvelles pour la Phase 2 (synchronisation cloud, voir [SyncQueueEntries]
/// et [ConflictHistoryEntries]).

@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get source => text()();
  TextColumn get type => text()();
  RealColumn get montant => real()();
  RealColumn get frais => real().withDefault(const Constant(0))();
  RealColumn get montantNet => real()();
  RealColumn get soldeApres => real().nullable()();
  TextColumn get contactNom => text().nullable()();
  TextColumn get contactNumero => text().nullable()();
  TextColumn get categorie => text().withDefault(const Constant('Autre'))();
  DateTimeColumn get dateTransaction => dateTime()();
  TextColumn get idTransactionOperateur => text().nullable()();
  TextColumn get smsBrut => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get statutEdition => text().withDefault(const Constant('auto'))();
  DateTimeColumn get derniereModification => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Règles de catégorisation apprises. Synchronisées vers Supabase
/// (table category_rules) sous l'identité (matchType, matchValue) — l'id
/// auto-incrémenté reste purement local.
@DataClassName('CategoryRuleRow')
class CategoryRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get matchType => text()();
  TextColumn get matchValue => text()();
  TextColumn get categorie => text()();
  // Défaut "plus ancien que tout" pour les lignes antérieures au schéma
  // v3 : SQLite n'accepte qu'une constante pour un ADD COLUMN.
  DateTimeColumn get derniereModification => dateTime().withDefault(Constant(DateTime.fromMillisecondsSinceEpoch(0)))();
}

/// Catégories proposées à l'utilisateur (écran Réglages > Catégories).
/// Seedée avec [categoriesParDefaut] à la création de la base, puis
/// synchronisée vers Supabase (table categories) sous l'identité
/// `lower(nom)`. Le champ `categorie` d'une transaction reste une simple
/// chaîne libre, donc supprimer une catégorie d'ici ne modifie jamais les
/// transactions qui l'utilisent déjà.
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nom => text()();
  DateTimeColumn get derniereModification => dateTime().withDefault(Constant(DateTime.fromMillisecondsSinceEpoch(0)))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {nom}
      ];
}

/// File d'attente de synchronisation : une entrée par écriture locale
/// (création, édition ou suppression) en attente de propagation vers
/// Supabase. Voir [lib/services/sync_service.dart].
@DataClassName('SyncQueueEntryRow')
class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  // transaction | category | category_rule (voir SyncEntity)
  TextColumn get entityType => text().withDefault(const Constant('transaction'))();
  // uuid pour une transaction, clé naturelle pour les autres (voir
  // AppDatabase.categoryKey / ruleKey).
  TextColumn get entityId => text()();
  // upsert | delete — la suppression voyage comme une pierre tombale
  // (`supprime: true` dans le payload).
  TextColumn get operation => text().withDefault(const Constant('upsert'))();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  // en_attente | synchronise | echec
  TextColumn get status => text().withDefault(const Constant('en_attente'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
}

/// Historique local des deux versions en cas de conflit (édition locale et
/// cloud divergentes) : conservé pour consultation même si la stratégie
/// "la modification la plus récente gagne" a déjà tranché automatiquement.
@DataClassName('ConflictHistoryRow')
class ConflictHistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get transactionId => text()();
  TextColumn get localVersionJson => text()();
  TextColumn get remoteVersionJson => text()();
  DateTimeColumn get detectedAt => dateTime()();
}

/// Curseur de pull par type d'entité : (synced_at, clé) de la dernière
/// ligne serveur reçue. synced_at est conservé tel que formaté pour la
/// requête (UTC, microsecondes) afin de ne rien perdre en précision.
@DataClassName('SyncCursorRow')
class SyncCursors extends Table {
  TextColumn get entityType => text()();
  TextColumn get syncedAt => text()();
  TextColumn get cle => text()();

  @override
  Set<Column> get primaryKey => {entityType};
}
