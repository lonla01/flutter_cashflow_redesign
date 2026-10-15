import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/category_rule.dart' show categoriesParDefaut;
import 'tables.dart';

part 'drift_database.g.dart';

@DriftDatabase(tables: [
  Transactions,
  CategoryRules,
  Categories,
  SyncQueueEntries,
  ConflictHistoryEntries,
  SyncCursors,
])
class AppDatabaseDrift extends _$AppDatabaseDrift {
  AppDatabaseDrift(super.executor);

  @override
  int get schemaVersion => 3;

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
          await _seedCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(categories);
            await _seedCategories();
          }
          if (from < 3) {
            await m.addColumn(categories, categories.derniereModification);
            await m.addColumn(categoryRules, categoryRules.derniereModification);
            await m.addColumn(syncQueueEntries, syncQueueEntries.entityType);
            await m.createTable(syncCursors);
            // L'ancien curseur unique reposait sur l'horloge des appareils ;
            // les curseurs neufs (vides) déclenchent un pull complet, sans
            // risque : appliquer une ligne déjà connue ne change rien.
            await customStatement('DROP TABLE IF EXISTS sync_meta_table');
            await _enqueueExistingCategoriesAndRules();
          }
        },
      );

  /// Passage au schéma v3 : catégories et règles n'étaient jusque-là
  /// jamais synchronisées. On pousse une fois l'état local existant — les
  /// catégories ajoutées et les règles apprises, plus une pierre tombale
  /// pour chaque catégorie par défaut supprimée — sinon il n'atteindrait
  /// jamais les autres appareils.
  Future<void> _enqueueExistingCategoriesAndRules() async {
    final now = DateTime.now();
    final ts = now.toIso8601String();

    Future<void> enqueue(String type, String id, String op, Map<String, Object?> payload) =>
        into(syncQueueEntries).insert(SyncQueueEntriesCompanion.insert(
          entityType: Value(type),
          entityId: id,
          operation: Value(op),
          payload: jsonEncode(payload),
          createdAt: now,
          updatedAt: now,
        ));

    final existantes = await select(categories).get();
    final cles = existantes.map((c) => c.nom.toLowerCase()).toSet();
    final parDefaut = categoriesParDefaut.map((c) => c.toLowerCase()).toSet();
    for (final c in existantes) {
      if (parDefaut.contains(c.nom.toLowerCase())) continue;
      await enqueue('category', c.nom.toLowerCase(), 'upsert',
          {'nom': c.nom, 'supprime': false, 'derniere_modification': ts});
    }
    for (final nom in categoriesParDefaut) {
      if (cles.contains(nom.toLowerCase())) continue;
      await enqueue('category', nom.toLowerCase(), 'delete',
          {'nom': nom, 'supprime': true, 'derniere_modification': ts});
    }
    await update(categories).write(CategoriesCompanion(derniereModification: Value(now)));

    for (final r in await select(categoryRules).get()) {
      await enqueue('category_rule', '${r.matchType}:${r.matchValue}', 'upsert', {
        'match_type': r.matchType,
        'match_value': r.matchValue,
        'categorie': r.categorie,
        'supprime': false,
        'derniere_modification': ts,
      });
    }
    await update(categoryRules).write(CategoryRulesCompanion(derniereModification: Value(now)));
  }

  Future<void> _seedCategories() async {
    await batch((b) {
      b.insertAll(
        categories,
        categoriesParDefaut.map((nom) => CategoriesCompanion.insert(nom: nom)).toList(),
      );
    });
  }
}
