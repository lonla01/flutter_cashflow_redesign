// Sélectionner une catégorie sur l'écran Transactions affiche le total de
// cette catégorie.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mobile_money_tracker/db/app_database.dart';
import 'package:mobile_money_tracker/models/transaction.dart';
import 'package:mobile_money_tracker/screens/home_screen.dart';

import '../support/sample_transaction.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  setUp(() {
    AppDatabase.instance = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() => AppDatabase.instance.close());

  testWidgets('total net et détail dépensé/reçu de la catégorie sélectionnée', (tester) async {
    await tester.runAsync(() async {
      final db = AppDatabase.instance;
      await db.insertTransactionIfNew(buildTransaction(montant: 5000, categorie: 'Alimentation'));
      await db.insertTransactionIfNew(buildTransaction(montant: 2000, categorie: 'Alimentation'));
      await db.insertTransactionIfNew(MoneyTransaction(
        source: TransactionSource.mtnMomo,
        type: TransactionType.reception,
        montant: 1500,
        categorie: 'Alimentation',
        contactNom: 'Remboursement',
        dateTransaction: DateTime.now(),
      ));
      await db.insertTransactionIfNew(buildTransaction(montant: 9000, categorie: 'Transport'));
    });

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    // Aucune catégorie sélectionnée : pas de carte de total.
    expect(find.textContaining('transactions'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Alimentation'));
    await tester.pump();

    final fmt = NumberFormat('#,##0', 'fr_FR');
    expect(find.text('Alimentation · 3 transactions'), findsOneWidget);
    expect(find.text('Dépensé ${fmt.format(7000)} · Reçu ${fmt.format(1500)} FCFA'), findsOneWidget);
    final net = tester.widget<Text>(find.text('-${fmt.format(5500)} FCFA'));
    expect(net.style!.color, Colors.red.shade700);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Toutes'));
    await tester.pump();
    expect(find.textContaining('transactions'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
