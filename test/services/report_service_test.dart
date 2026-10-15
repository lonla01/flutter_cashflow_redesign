import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_tracker/models/transaction.dart';
import 'package:mobile_money_tracker/services/report_service.dart';

MoneyTransaction _tx(String contact, TransactionType type, double montant, {double frais = 0}) =>
    MoneyTransaction(
      source: TransactionSource.mtnMomo,
      type: type,
      montant: montant,
      frais: frais,
      montantNet: type == TransactionType.reception ? montant : montant + frais,
      contactNom: contact,
      dateTransaction: DateTime(2026, 10, 1),
    );

void main() {
  test('totauxParContact : solde net signé, trié par importance', () {
    final totaux = ReportService.totauxParContact([
      _tx('Alice', TransactionType.reception, 10000),
      _tx('Alice', TransactionType.transfertEnvoye, 3000, frais: 50),
      _tx('Bob', TransactionType.transfertEnvoye, 20000, frais: 100),
      _tx('Carole', TransactionType.reception, 500),
    ]);

    expect(totaux.map((c) => c.contact), ['Bob', 'Alice', 'Carole']);
    expect(totaux[0].total, -20100);
    expect(totaux[1].total, 6950);
    expect(totaux[2].total, 500);
  });
}
