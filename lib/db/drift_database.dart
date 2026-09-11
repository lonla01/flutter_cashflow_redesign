import 'package:drift/drift.dart';

import 'tables.dart';

part 'drift_database.g.dart';

@DriftDatabase(tables: [
  Transactions,
  CategoryRules,
  SyncQueueEntries,
  ConflictHistoryEntries,
  SyncMetaTable,
])
class AppDatabaseDrift extends _$AppDatabaseDrift {
  AppDatabaseDrift(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Index unique partiel : un même id_transaction_operateur ne doit
          // jamais être inséré deux fois (dédup lors d'un rescan SMS).
          // Non exprimable déclarativement avec l'API Table de Drift.
          await customStatement(
            'CREATE UNIQUE INDEX idx_transactions_operateur_id '
            'ON transactions(id_transaction_operateur) '
            'WHERE id_transaction_operateur IS NOT NULL',
          );
          await into(syncMetaTable).insert(
            const SyncMetaTableCompanion(
              id: Value(0),
              lastPulledAt: Value(null),
            ),
          );
        },
      );
}
