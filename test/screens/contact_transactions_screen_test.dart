import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mobile_money_tracker/models/transaction.dart';
import 'package:mobile_money_tracker/screens/contact_transactions_screen.dart';
import 'package:mobile_money_tracker/widgets/transaction_tile.dart';

MoneyTransaction _tx(TransactionType type, double montant, int jour) => MoneyTransaction(
      source: TransactionSource.mtnMomo,
      type: type,
      montant: montant,
      contactNom: 'Alice',
      dateTransaction: DateTime(2026, 10, jour),
    );

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  testWidgets('liste les transactions du contact, la plus récente d\'abord, avec le solde net',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ContactTransactionsScreen(
        contact: 'Alice',
        periode: 'Octobre 2026',
        total: -2000,
        transactions: [
          _tx(TransactionType.reception, 1000, 3),
          _tx(TransactionType.transfertEnvoye, 3000, 9),
        ],
      ),
    ));

    expect(find.text('Alice'), findsWidgets);
    expect(find.text('2 transactions · solde net'), findsOneWidget);
    // Séparateur de milliers fr_FR : espace fine insécable, pas une espace.
    final montant = NumberFormat('#,##0', 'fr_FR').format(2000);
    final solde = tester.widget<Text>(find.text('-$montant FCFA'));
    expect(solde.style!.color, Colors.red.shade700);

    final tuiles = tester.widgetList<TransactionTile>(find.byType(TransactionTile)).toList();
    expect(tuiles.map((t) => t.transaction.dateTransaction.day), [9, 3]);
  });
}
