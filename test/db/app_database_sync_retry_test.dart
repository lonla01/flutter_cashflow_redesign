import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_money_tracker/db/app_database.dart';

import '../support/sample_transaction.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('forceRetryAllPending', () {
    test('efface le backoff des entrées en_attente pour les rendre à nouveau syncables', () async {
      await db.insertTransactionIfNew(buildTransaction());
      final entry = (await db.getSyncableEntries()).single;
      await db.markSyncEntry(
        entry.id,
        status: 'en_attente',
        attemptCount: 3,
        nextAttemptAt: DateTime.now().add(const Duration(minutes: 5)),
        lastError: 'erreur réseau',
      );

      expect(await db.getSyncableEntries(), isEmpty);

      await db.forceRetryAllPending();

      final syncables = await db.getSyncableEntries();
      expect(syncables, hasLength(1));
      expect(syncables.single.attemptCount, 0);
      expect(syncables.single.nextAttemptAt, isNull);
    });

    test('remet aussi en attente les entrées en échec', () async {
      await db.insertTransactionIfNew(buildTransaction());
      final entry = (await db.getSyncableEntries()).single;
      await db.markSyncEntry(entry.id, status: 'echec', lastError: 'accès refusé');

      expect(await db.hasFailedSyncEntries(), isTrue);

      await db.forceRetryAllPending();

      expect(await db.hasFailedSyncEntries(), isFalse);
      expect(await db.getSyncableEntries(), hasLength(1));
    });
  });
}
