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

  group('bulkSetCategory', () {
    test('recatégorise uniquement les transactions sélectionnées', () async {
      final a = buildTransaction(categorie: 'Autre');
      final b = buildTransaction(categorie: 'Autre');
      final c = buildTransaction(categorie: 'Autre');
      await db.insertTransactionIfNew(a);
      await db.insertTransactionIfNew(b);
      await db.insertTransactionIfNew(c);

      final count = await db.bulkSetCategory([a.id, b.id], 'Transport');

      expect(count, 2);
      final toutes = await db.getAllTransactions();
      expect(toutes.firstWhere((t) => t.id == a.id).categorie, 'Transport');
      expect(toutes.firstWhere((t) => t.id == b.id).categorie, 'Transport');
      expect(toutes.firstWhere((t) => t.id == c.id).categorie, 'Autre');
    });

    test('ignore une liste vide', () async {
      final count = await db.bulkSetCategory([], 'Transport');
      expect(count, 0);
    });

    test('ne compte pas les transactions déjà dans la catégorie cible', () async {
      final a = buildTransaction(categorie: 'Transport');
      await db.insertTransactionIfNew(a);

      final count = await db.bulkSetCategory([a.id], 'Transport');

      expect(count, 0);
    });

    test('met en file de synchronisation chaque transaction modifiée', () async {
      final a = buildTransaction(categorie: 'Autre');
      await db.insertTransactionIfNew(a);
      final avant = (await db.getSyncableEntries()).length;

      await db.bulkSetCategory([a.id], 'Transport');

      final apres = (await db.getSyncableEntries()).length;
      expect(apres, avant + 1);
    });
  });
}
