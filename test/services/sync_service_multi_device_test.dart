// Synchronisation de bout en bout entre deux "appareils" (deux bases Drift
// en mémoire) via un faux serveur qui reproduit la sémantique des RPC
// sync_upsert_* (last-write-wins sur derniere_modification) et du pull
// paginé par curseur (synced_at, clé).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_tracker/db/app_database.dart';
import 'package:mobile_money_tracker/models/category_rule.dart';
import 'package:mobile_money_tracker/services/sync_service.dart';
import 'package:mobile_money_tracker/services/sync_transport.dart';

import '../support/fakes.dart';
import '../support/sample_transaction.dart';

class _FakeServer implements SyncTransport {
  final Map<SyncEntity, Map<String, Map<String, Object?>>> tables = {
    for (final e in SyncEntity.values) e: {},
  };
  int _clock = 0;
  int pullCalls = 0;

  String _key(SyncEntity entity, Map<String, Object?> payload) => switch (entity) {
        SyncEntity.transaction => payload['id'] as String,
        SyncEntity.category => (payload['nom'] as String).toLowerCase(),
        SyncEntity.categoryRule => '${payload['match_type']}:${payload['match_value']}',
      };

  @override
  Future<Map<String, Object?>> push(SyncEntity entity, Map<String, Object?> payload) async {
    final key = _key(entity, payload);
    final table = tables[entity]!;
    final existing = table[key];
    final ts = DateTime.parse(payload['derniere_modification'] as String);
    if (existing == null ||
        ts.isAfter(DateTime.parse(existing['derniere_modification'] as String))) {
      table[key] = {
        ...payload,
        if (entity != SyncEntity.transaction) 'cle': key,
        'supprime': payload['supprime'] ?? false,
        'synced_at': DateTime.utc(2026).add(Duration(microseconds: ++_clock)).toIso8601String(),
      };
    }
    return Map.of(table[key]!);
  }

  @override
  Future<List<Map<String, Object?>>> pullPage(SyncEntity entity, SyncCursor? after) async {
    pullCalls++;
    final rows = tables[entity]!.values.toList()
      ..sort((a, b) {
        final c = (a['synced_at'] as String).compareTo(b['synced_at'] as String);
        return c != 0 ? c : '${a[entity.keyColumn]}'.compareTo('${b[entity.keyColumn]}');
      });
    return rows
        .where((r) {
          if (after == null) return true;
          final c = DateTime.parse(r['synced_at'] as String)
              .compareTo(DateTime.parse(after.syncedAt));
          return c > 0 || (c == 0 && '${r[entity.keyColumn]}'.compareTo(after.cle) > 0);
        })
        .take(SyncTransport.pageSize)
        .map(Map<String, Object?>.of)
        .toList();
  }
}

void main() {
  late _FakeServer server;
  late AppDatabase dbA;
  late AppDatabase dbB;
  late SyncService syncA;
  late SyncService syncB;

  SyncService buildSync(AppDatabase db) => SyncService(
        db: db,
        connectivity: FakeConnectivityChecker(),
        transport: server,
      );

  setUp(() {
    server = _FakeServer();
    dbA = AppDatabase.withExecutor(NativeDatabase.memory());
    dbB = AppDatabase.withExecutor(NativeDatabase.memory());
    syncA = buildSync(dbA);
    syncB = buildSync(dbB);
  });

  tearDown(() async {
    await dbA.close();
    await dbB.close();
  });

  Future<List<String>> categories(AppDatabase db) => db.watchCategories().first;

  test('une transaction supprimée sur A disparaît aussi sur B', () async {
    final tx = buildTransaction(idTransactionOperateur: 'OP1');
    await dbA.insertTransactionIfNew(tx);
    await syncA.retryNow();
    await syncB.retryNow();
    expect((await dbB.getAllTransactions()).map((t) => t.id), [tx.id]);

    await dbA.deleteTransaction(tx.id);
    await syncA.retryNow();
    await syncB.retryNow();

    expect(server.tables[SyncEntity.transaction]![tx.id]!['supprime'], isTrue);
    expect(await dbB.getAllTransactions(), isEmpty);
  });

  test('un pull ne ressuscite pas une suppression locale pas encore poussée', () async {
    final tx = buildTransaction();
    await dbA.insertTransactionIfNew(tx);
    await syncA.retryNow();

    await dbA.deleteTransaction(tx.id);
    // La pierre tombale est en file mais pas encore poussée : une version
    // serveur vivante tirée entre-temps ne doit pas recréer la ligne.
    await dbA.applyRemoteTransaction(
      buildTransaction(id: tx.id)..derniereModification = DateTime.now().add(const Duration(days: 1)),
    );
    expect(await dbA.getAllTransactions(), isEmpty);
  });

  test('catégories ajoutées et supprimées sur A se propagent à B', () async {
    await dbA.addCategory('Épargne');
    await dbA.removeCategory('Loisirs');
    await syncA.retryNow();
    await syncB.retryNow();

    final surB = await categories(dbB);
    expect(surB, contains('Épargne'));
    expect(surB, isNot(contains('Loisirs')));
  });

  test('une catégorie à majuscule accentuée se synchronise sans doublon', () async {
    await dbA.addCategory('Électricité');
    await syncA.retryNow();
    await syncB.retryNow();
    await syncA.retryNow();

    expect(await categories(dbB), contains('Électricité'));
    expect((await categories(dbA)).where((c) => c == 'Électricité'), hasLength(1));
    await dbA.addCategory('électricité');
    expect((await categories(dbA)).where((c) => c.toLowerCase() == 'électricité'), hasLength(1));
    expect(await dbA.getSyncableEntries(), isEmpty);
  });

  test('une catégorie recréée après suppression revient sur les autres appareils', () async {
    await dbA.removeCategory('Loisirs');
    await syncA.retryNow();
    await syncB.retryNow();
    expect(await categories(dbB), isNot(contains('Loisirs')));

    await Future<void>.delayed(const Duration(seconds: 1));
    await dbB.addCategory('Loisirs');
    await syncB.retryNow();
    await syncA.retryNow();

    expect(await categories(dbA), contains('Loisirs'));
  });

  test('les règles de catégorisation apprises sur A s\'appliquent sur B', () async {
    await dbA.upsertCategoryRule(CategoryRule(
      matchType: 'contact_numero',
      matchValue: '690000000',
      categorie: 'Transport',
    ));
    await syncA.retryNow();
    await syncB.retryNow();

    final regles = await dbB.getCategoryRules();
    expect(regles.single.matchValue, '690000000');
    expect(regles.single.categorie, 'Transport');

    await Future<void>.delayed(const Duration(seconds: 1));
    await dbA.upsertCategoryRule(CategoryRule(
      matchType: 'contact_numero',
      matchValue: '690000000',
      categorie: 'Alimentation',
    ));
    await syncA.retryNow();
    await syncB.retryNow();

    expect((await dbB.getCategoryRules()).single.categorie, 'Alimentation');
  });

  test('le pull pagine au-delà d\'une page complète', () async {
    const total = SyncTransport.pageSize + 3;
    for (var i = 0; i < total; i++) {
      await server.push(SyncEntity.transaction, {
        ...buildTransaction(idTransactionOperateur: 'OP$i').toMap(),
        'supprime': false,
      });
    }
    await syncB.retryNow();
    expect(await dbB.countTransactions(), total);

    // Curseur sauvegardé : un nouveau cycle ne retire rien.
    final avant = server.pullCalls;
    await syncB.retryNow();
    expect(server.pullCalls - avant, SyncEntity.values.length);
    expect(await dbB.countTransactions(), total);
  });
}
