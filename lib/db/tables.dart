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

@DataClassName('CategoryRuleRow')
class CategoryRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get matchType => text()();
  TextColumn get matchValue => text()();
  TextColumn get categorie => text()();
}

/// File d'attente de synchronisation : une entrée par écriture locale
/// (nouvelle transaction ou édition) en attente de propagation vers
/// Supabase. Voir [lib/services/sync_service.dart].
@DataClassName('SyncQueueEntryRow')
class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityId => text()();
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

/// Table mono-ligne (id fixe = 0) de métadonnées de synchronisation.
@DataClassName('SyncMetaRow')
class SyncMetaTable extends Table {
  IntColumn get id => integer()();
  DateTimeColumn get lastPulledAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
