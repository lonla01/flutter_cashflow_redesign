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

  group('getUniqueContactNames', () {
    test('renvoie les noms distincts, triés, sans doublon ni vide', () async {
      await db.insertTransactionIfNew(buildTransaction(contactNom: 'Boutique B'));
      await db.insertTransactionIfNew(buildTransaction(contactNom: 'Boutique A'));
      await db.insertTransactionIfNew(buildTransaction(contactNom: 'Boutique A'));
      await db.insertTransactionIfNew(buildTransaction(contactNom: null));
      await db.insertTransactionIfNew(buildTransaction(contactNom: '  '));

      final contacts = await db.getUniqueContactNames();

      expect(contacts, ['Boutique A', 'Boutique B']);
    });
  });

  group('associateContactWithCategory', () {
    test('réassigne toutes les transactions existantes de ce contact', () async {
      final a = buildTransaction(contactNom: 'Boutique X', categorie: 'Autre');
      final b = buildTransaction(contactNom: 'Boutique X', categorie: 'Autre');
      final autre = buildTransaction(contactNom: 'Boutique Y', categorie: 'Autre');
      await db.insertTransactionIfNew(a);
      await db.insertTransactionIfNew(b);
      await db.insertTransactionIfNew(autre);

      final nb = await db.associateContactWithCategory('Boutique X', 'Alimentation');

      expect(nb, 2);
      final toutes = await db.getAllTransactions();
      expect(toutes.firstWhere((t) => t.id == a.id).categorie, 'Alimentation');
      expect(toutes.firstWhere((t) => t.id == b.id).categorie, 'Alimentation');
      expect(toutes.firstWhere((t) => t.id == autre.id).categorie, 'Autre');
    });

    test('mémorise une règle réutilisée par la suggestion de catégorie', () async {
      await db.associateContactWithCategory('Boutique Z', 'Transport');

      final regles = await db.getCategoryRules();
      expect(regles, hasLength(1));
      expect(regles.single.matchType, 'contact_nom_contains');
      expect(regles.single.matchValue, 'Boutique Z');
      expect(regles.single.categorie, 'Transport');
    });

    test('un second appel sur le même contact met à jour la règle plutôt que d\'en dupliquer une', () async {
      await db.associateContactWithCategory('Boutique Z', 'Transport');
      await db.associateContactWithCategory('Boutique Z', 'Santé');

      final regles = await db.getCategoryRules();
      expect(regles, hasLength(1));
      expect(regles.single.categorie, 'Santé');
    });
  });
}
