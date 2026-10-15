// Glisser pour supprimer dans l'onglet Récents : la transaction disparaît,
// une pierre tombale est mise en file de synchronisation, et "Annuler" la
// restaure.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_money_tracker/db/app_database.dart';
import 'package:mobile_money_tracker/screens/recents_screen.dart';
import 'package:mobile_money_tracker/widgets/transaction_tile.dart';

import '../support/sample_transaction.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  setUp(() {
    AppDatabase.instance = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() => AppDatabase.instance.close());

  testWidgets('glisser supprime la transaction, "Annuler" la restaure', (tester) async {
    final tx = buildTransaction(contactNom: 'Boutique Swipe');
    await tester.runAsync(() => AppDatabase.instance.insertTransactionIfNew(tx));

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: RecentsScreen())));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    expect(find.text('Boutique Swipe'), findsOneWidget);

    await tester.drag(find.byType(TransactionTile), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    expect(find.byType(TransactionTile), findsNothing);
    expect(await tester.runAsync(AppDatabase.instance.countTransactions), 0);
    final entrees = await tester.runAsync(AppDatabase.instance.getSyncableEntries);
    expect(entrees!.last.operation, 'delete');

    await tester.tap(find.text('Annuler'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('Boutique Swipe'), findsOneWidget);
    expect(await tester.runAsync(AppDatabase.instance.countTransactions), 1);

    // Démonte l'arbre avant la fin du test (voir widget_test.dart : le
    // nettoyage des streams Drift programme un Timer.zero).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
