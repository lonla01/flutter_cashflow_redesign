import 'dart:convert';

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

  const serverId = '11111111-1111-4111-8111-111111111111';

  test('reassignTransactionId réaligne la transaction et ses entrées sync_queue', () async {
    final tx = buildTransaction(idTransactionOperateur: 'OP123');
    await db.insertTransactionIfNew(tx);

    await db.reassignTransactionId(tx.id, serverId);

    final all = await db.getAllTransactions();
    expect(all.single.id, serverId);
    final entry = (await db.getSyncableEntries()).single;
    expect(entry.entityId, serverId);
    expect((jsonDecode(entry.payload) as Map)['id'], serverId);
  });

  test('applyRemoteTransaction adopte l\'id serveur pour un même id opérateur', () async {
    final local = buildTransaction(idTransactionOperateur: 'OP123');
    await db.insertTransactionIfNew(local);

    final remote = buildTransaction(
      id: serverId,
      idTransactionOperateur: 'OP123',
      categorie: 'Transport',
    )..derniereModification = DateTime.now().add(const Duration(minutes: 1));

    await db.applyRemoteTransaction(remote);

    final all = await db.getAllTransactions();
    expect(all, hasLength(1));
    expect(all.single.id, serverId);
    expect(all.single.categorie, 'Transport');
  });
}
