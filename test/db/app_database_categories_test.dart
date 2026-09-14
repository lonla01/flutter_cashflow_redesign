import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_money_tracker/db/app_database.dart';
import 'package:mobile_money_tracker/models/category_rule.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('catégories', () {
    test('la base fraîchement créée est pré-remplie avec les catégories par défaut', () async {
      final categories = await db.watchCategories().first;
      expect(categories.toSet(), categoriesParDefaut.toSet());
    });

    test('addCategory ajoute une nouvelle catégorie', () async {
      await db.addCategory('Épargne');

      final categories = await db.watchCategories().first;
      expect(categories, contains('Épargne'));
    });

    test('addCategory ignore silencieusement un doublon insensible à la casse', () async {
      final avant = await db.watchCategories().first;

      await db.addCategory('alimentation');

      final apres = await db.watchCategories().first;
      expect(apres.length, avant.length);
    });

    test('addCategory ignore un nom vide ou blanc', () async {
      final avant = await db.watchCategories().first;

      await db.addCategory('   ');

      final apres = await db.watchCategories().first;
      expect(apres.length, avant.length);
    });

    test('removeCategory retire une catégorie existante', () async {
      await db.removeCategory('Loisirs');

      final categories = await db.watchCategories().first;
      expect(categories, isNot(contains('Loisirs')));
    });
  });
}
