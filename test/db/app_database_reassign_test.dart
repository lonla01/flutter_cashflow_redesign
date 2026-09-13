import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_money_tracker/db/app_database.dart';
import 'package:mobile_money_tracker/models/transaction.dart';

import '../support/sample_transaction.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('reassignSimilarTransactions', () {
    test('recatégorise les autres transactions du même contactNumero', () async {
      final source = buildTransaction(categorie: 'Alimentation')
        ..contactNumero = '691000000';
      final memeNumero = buildTransaction(categorie: 'Autre')
        ..contactNumero = '691000000';
      final numeroDifferent = buildTransaction(categorie: 'Autre')
        ..contactNumero = '699999999';

      await db.insertTransactionIfNew(source);
      await db.insertTransactionIfNew(memeNumero);
      await db.insertTransactionIfNew(numeroDifferent);

      final count = await db.reassignSimilarTransactions(source, 'Alimentation');

      expect(count, 1);
      final toutes = await db.getAllTransactions();
      final maj = toutes.firstWhere((t) => t.id == memeNumero.id);
      final inchangee = toutes.firstWhere((t) => t.id == numeroDifferent.id);
      expect(maj.categorie, 'Alimentation');
      expect(inchangee.categorie, 'Autre');
    });

    test('ne réassigne jamais la transaction elle-même', () async {
      final source = buildTransaction(categorie: 'Alimentation')
        ..contactNumero = '691000000';
      await db.insertTransactionIfNew(source);

      final count = await db.reassignSimilarTransactions(source, 'Alimentation');

      expect(count, 0);
    });

    test('se rabat sur contactNom quand contactNumero est absent', () async {
      final source = buildTransaction(categorie: 'Santé', contactNom: 'Pharmacie X');
      final memeNom = buildTransaction(categorie: 'Autre', contactNom: 'Pharmacie X');
      final nomDifferent = buildTransaction(categorie: 'Autre', contactNom: 'Autre Boutique');

      await db.insertTransactionIfNew(source);
      await db.insertTransactionIfNew(memeNom);
      await db.insertTransactionIfNew(nomDifferent);

      final count = await db.reassignSimilarTransactions(source, 'Santé');

      expect(count, 1);
      final toutes = await db.getAllTransactions();
      expect(toutes.firstWhere((t) => t.id == memeNom.id).categorie, 'Santé');
      expect(toutes.firstWhere((t) => t.id == nomDifferent.id).categorie, 'Autre');
    });

    test('sans contact ni nom, ne réassigne rien', () async {
      final source = MoneyTransaction(
        source: TransactionSource.orangeMoney,
        type: TransactionType.paiementMarchand,
        montant: 1000,
        categorie: 'Alimentation',
        dateTransaction: DateTime.now(),
      );
      await db.insertTransactionIfNew(source);

      final count = await db.reassignSimilarTransactions(source, 'Autre');

      expect(count, 0);
    });

    test('met en file de synchronisation chaque transaction réassignée', () async {
      final source = buildTransaction(categorie: 'Alimentation')
        ..contactNumero = '691000000';
      final memeNumero = buildTransaction(categorie: 'Autre')
        ..contactNumero = '691000000';
      await db.insertTransactionIfNew(source);
      await db.insertTransactionIfNew(memeNumero);

      final avant = (await db.getSyncableEntries()).length;
      await db.reassignSimilarTransactions(source, 'Alimentation');
      final apres = (await db.getSyncableEntries()).length;

      expect(apres, avant + 1);
    });
  });
}
