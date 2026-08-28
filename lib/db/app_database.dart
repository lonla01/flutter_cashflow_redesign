import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

import '../models/category_rule.dart';
import '../models/transaction.dart';

/// Accès unique à la base locale. La base locale est la source de
/// vérité immédiate de l'app (voir prompt Phase 2 pour la synchro cloud
/// à venir) : toute écriture passe par ici en premier, sans dépendance réseau.
///
/// Sur mobile (Android/iOS), la vraie base SQLite (sqflite) est utilisée.
/// Sur le web, sqflite n'a pas de sens ici : la lecture des SMS n'existe
/// pas dans un navigateur, donc le mode web ne sert qu'à itérer sur l'UI.
/// On utilise alors un stockage 100% en mémoire (perdu au refresh), pour
/// éviter toute la mise en place de sqflite_common_ffi_web / wasm.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  // ---------------------------------------------------------------------
  // Stockage en mémoire (web uniquement)
  // ---------------------------------------------------------------------
  final List<Map<String, Object?>> _memTransactions = [];
  final List<Map<String, Object?>> _memCategoryRules = [];
  int _memCategoryRuleNextId = 1;

  Future<Database> get database async {
    assert(!kIsWeb, 'database ne doit pas être utilisé sur le web, utiliser les méthodes publiques qui branchent automatiquement.');
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'mobile_money_tracker.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _createSchema,
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            source TEXT NOT NULL,
            type TEXT NOT NULL,
            montant REAL NOT NULL,
            frais REAL NOT NULL DEFAULT 0,
            montant_net REAL NOT NULL,
            solde_apres REAL,
            contact_nom TEXT,
            contact_numero TEXT,
            categorie TEXT NOT NULL DEFAULT 'Autre',
            date_transaction TEXT NOT NULL,
            id_transaction_operateur TEXT,
            sms_brut TEXT,
            notes TEXT NOT NULL DEFAULT '',
            statut_edition TEXT NOT NULL DEFAULT 'auto',
            derniere_modification TEXT NOT NULL
          );
        ''');

    // Un même id_transaction_operateur ne doit jamais être inséré deux
    // fois : c'est la clé de déduplication lors d'un rescan de
    // l'historique SMS.
    await db.execute('''
          CREATE UNIQUE INDEX idx_transactions_operateur_id
          ON transactions(id_transaction_operateur)
          WHERE id_transaction_operateur IS NOT NULL;
        ''');

    await db.execute('''
          CREATE TABLE category_rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            match_type TEXT NOT NULL,
            match_value TEXT NOT NULL,
            categorie TEXT NOT NULL
          );
        ''');
  }

  // ---------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------

  /// Insère une transaction. Retourne false sans lever d'erreur si une
  /// transaction avec le même id_transaction_operateur existe déjà.
  Future<bool> insertTransactionIfNew(MoneyTransaction tx) async {
    if (kIsWeb) {
      if (tx.idTransactionOperateur != null) {
        final exists = _memTransactions.any(
          (row) => row['id_transaction_operateur'] == tx.idTransactionOperateur,
        );
        if (exists) return false;
      }
      _memTransactions.add(tx.toMap());
      return true;
    }

    final db = await database;
    if (tx.idTransactionOperateur != null) {
      final existing = await db.query(
        'transactions',
        where: 'id_transaction_operateur = ?',
        whereArgs: [tx.idTransactionOperateur],
        limit: 1,
      );
      if (existing.isNotEmpty) return false;
    }
    await db.insert(
      'transactions',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return true;
  }

  Future<void> updateTransaction(MoneyTransaction tx) async {
    tx.derniereModification = DateTime.now();

    if (kIsWeb) {
      final index = _memTransactions.indexWhere((row) => row['id'] == tx.id);
      if (index != -1) {
        _memTransactions[index] = tx.toMap();
      }
      return;
    }

    final db = await database;
    await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<List<MoneyTransaction>> getAllTransactions({
    DateTime? from,
    DateTime? to,
  }) async {
    if (kIsWeb) {
      final rows = _memTransactions.where((row) {
        final dateStr = row['date_transaction'] as String?;
        if (dateStr == null) return true;
        final date = DateTime.parse(dateStr);
        if (from != null && date.isBefore(from)) return false;
        if (to != null && date.isAfter(to)) return false;
        return true;
      }).toList();
      rows.sort((a, b) => (b['date_transaction'] as String)
          .compareTo(a['date_transaction'] as String));
      return rows.map(MoneyTransaction.fromMap).toList();
    }

    final db = await database;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('date_transaction >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('date_transaction <= ?');
      args.add(to.toIso8601String());
    }
    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date_transaction DESC',
    );
    return rows.map(MoneyTransaction.fromMap).toList();
  }

  Future<int> countTransactions() async {
    if (kIsWeb) {
      return _memTransactions.length;
    }
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM transactions');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<void> deleteAllTransactions() async {
    if (kIsWeb) {
      _memTransactions.clear();
      return;
    }
    final db = await database;
    await db.delete('transactions');
  }

  // ---------------------------------------------------------------------
  // Règles de catégorisation
  // ---------------------------------------------------------------------

  Future<void> upsertCategoryRule(CategoryRule rule) async {
    if (kIsWeb) {
      final index = _memCategoryRules.indexWhere((row) =>
          row['match_type'] == rule.matchType &&
          row['match_value'] == rule.matchValue);
      if (index != -1) {
        _memCategoryRules[index] = {
          ..._memCategoryRules[index],
          'categorie': rule.categorie,
        };
      } else {
        final map = rule.toMap();
        map['id'] = _memCategoryRuleNextId++;
        _memCategoryRules.add(map);
      }
      return;
    }

    final db = await database;
    final existing = await db.query(
      'category_rules',
      where: 'match_type = ? AND match_value = ?',
      whereArgs: [rule.matchType, rule.matchValue],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.update(
        'category_rules',
        {'categorie': rule.categorie},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('category_rules', rule.toMap());
    }
  }

  Future<List<CategoryRule>> getCategoryRules() async {
    if (kIsWeb) {
      return _memCategoryRules.map(CategoryRule.fromMap).toList();
    }
    final db = await database;
    final rows = await db.query('category_rules');
    return rows.map(CategoryRule.fromMap).toList();
  }
}