// Passage du schéma local v2 -> v3 (synchronisation des catégories et des
// règles) sur une base créée avec l'ancien schéma, comme sur un appareil
// déjà installé.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_tracker/db/app_database.dart';
import 'package:mobile_money_tracker/models/category_rule.dart';
import 'package:mobile_money_tracker/services/sync_transport.dart';

/// [execute] : exécuteur SQL brut de la base sqlite3 sous-jacente.
void _creerBaseV2(void Function(String sql) execute) {
  execute('''
    CREATE TABLE transactions (
      id TEXT NOT NULL PRIMARY KEY, source TEXT NOT NULL, type TEXT NOT NULL,
      montant REAL NOT NULL, frais REAL NOT NULL DEFAULT 0, montant_net REAL NOT NULL,
      solde_apres REAL, contact_nom TEXT, contact_numero TEXT,
      categorie TEXT NOT NULL DEFAULT 'Autre', date_transaction INTEGER NOT NULL,
      id_transaction_operateur TEXT, sms_brut TEXT, notes TEXT NOT NULL DEFAULT '',
      statut_edition TEXT NOT NULL DEFAULT 'auto', derniere_modification INTEGER NOT NULL);
    CREATE UNIQUE INDEX idx_transactions_operateur_id ON transactions(id_transaction_operateur)
      WHERE id_transaction_operateur IS NOT NULL;
    CREATE TABLE category_rules (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, match_type TEXT NOT NULL,
      match_value TEXT NOT NULL, categorie TEXT NOT NULL);
    CREATE TABLE categories (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, nom TEXT NOT NULL, UNIQUE(nom));
    CREATE TABLE sync_queue_entries (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, entity_id TEXT NOT NULL,
      operation TEXT NOT NULL DEFAULT 'upsert', payload TEXT NOT NULL,
      created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'en_attente', attempt_count INTEGER NOT NULL DEFAULT 0,
      last_error TEXT, next_attempt_at INTEGER);
    CREATE TABLE conflict_history_entries (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, transaction_id TEXT NOT NULL,
      local_version_json TEXT NOT NULL, remote_version_json TEXT NOT NULL,
      detected_at INTEGER NOT NULL);
    CREATE TABLE sync_meta_table (id INTEGER NOT NULL PRIMARY KEY, last_pulled_at INTEGER);
    INSERT INTO sync_meta_table VALUES (0, NULL);
    INSERT INTO sync_queue_entries (entity_id, payload, created_at, updated_at)
      VALUES ('tx-1', '{}', 0, 0);
    INSERT INTO category_rules (match_type, match_value, categorie)
      VALUES ('contact_numero', '690000000', 'Transport');
  ''');
  for (final nom in [...categoriesParDefaut.where((c) => c != 'Loisirs'), 'Épargne']) {
    execute("INSERT INTO categories (nom) VALUES ('${nom.replaceAll("'", "''")}')");
  }
  execute('PRAGMA user_version = 2');
}

void main() {
  test('v2 -> v3 met en file l\'état existant des catégories et des règles', () async {
    final db = AppDatabase.withExecutor(NativeDatabase.memory(setup: (raw) {
      if (raw.select('PRAGMA user_version').single.values.first == 0) _creerBaseV2(raw.execute);
    }));
    addTearDown(db.close);

    final entrees = await db.getSyncableEntries();
    final parType = {
      for (final e in entrees) '${e.entityType}/${e.entityId}': e,
    };

    // L'entrée v2 existante devient une entrée de transaction.
    expect(parType.containsKey('transaction/tx-1'), isTrue);
    // Catégorie ajoutée -> upsert ; catégorie par défaut supprimée -> pierre
    // tombale ; catégories par défaut encore présentes -> rien.
    expect(parType['category/épargne']!.operation, 'upsert');
    expect(parType['category/loisirs']!.operation, 'delete');
    expect(jsonDecode(parType['category/loisirs']!.payload)['supprime'], isTrue);
    expect(parType.keys.where((k) => k.startsWith('category/')), hasLength(2));
    // Règle existante -> upsert.
    expect(parType['category_rule/contact_numero:690000000']!.operation, 'upsert');

    // La base reste utilisable normalement après migration.
    expect(await db.watchCategories().first, contains('Épargne'));
    expect((await db.getCategoryRules()).single.categorie, 'Transport');
    expect(await db.getSyncCursor(SyncEntity.transaction), isNull);
  });
}
