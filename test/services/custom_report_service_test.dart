import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_tracker/models/transaction.dart';
import 'package:mobile_money_tracker/services/custom_report_service.dart';
import 'package:mobile_money_tracker/services/export_service.dart';

MoneyTransaction _tx(String? contact, String categorie, double montant, int jour,
        {TransactionType type = TransactionType.paiementMarchand}) =>
    MoneyTransaction(
      source: TransactionSource.mtnMomo,
      type: type,
      montant: montant,
      contactNom: contact,
      categorie: categorie,
      dateTransaction: DateTime(2026, 9, jour, 10),
    );

final _transactions = [
  _tx('Boutique', 'Alimentation', 12000, 15),
  _tx('Boutique', 'Alimentation', 18000, 2),
  _tx('Marché', 'Alimentation', 18500, 7),
  _tx('Station', 'Transport', 21000, 3),
  _tx('Boutique', 'Transport', 1000, 4),
  _tx('Alice', 'Revenus/Réceptions', 50000, 5, type: TransactionType.reception),
  _tx(null, 'Autre', 300, 6),
  // Hors période.
  _tx('Boutique', 'Alimentation', 999, 30),
];

final _septembre = ReportCriteria(
  debut: DateTime(2026, 9, 1),
  fin: DateTime(2026, 9, 29, 23, 59, 59),
);

void main() {
  group('buildCustomReport', () {
    test('catégorie puis contact : sous-totaux, tri par importance, ordre chronologique', () {
      final r = buildCustomReport(_transactions, _septembre, ReportGrouping.categorieContact);

      expect(r.groupes.map((g) => g.libelle),
          ['Revenus/Réceptions', 'Alimentation', 'Transport', 'Autre']);
      final alimentation = r.groupes[1];
      expect(alimentation.total, -48500);
      expect(alimentation.sousGroupes.map((s) => s.libelle), ['Boutique', 'Marché']);
      expect(alimentation.sousGroupes.first.total, -30000);
      expect(alimentation.sousGroupes.first.transactions.map((t) => t.dateTransaction.day),
          [2, 15]);
      expect(r.groupes.last.sousGroupes.single.libelle, contactInconnu);

      expect(r.nombre, 7);
      expect(r.depense, 70800);
      expect(r.recu, 50000);
      expect(r.total, -20800);
    });

    test('contact puis catégorie', () {
      final r = buildCustomReport(_transactions, _septembre, ReportGrouping.contactCategorie);
      final boutique = r.groupes.firstWhere((g) => g.libelle == 'Boutique');
      expect(boutique.sousGroupes.map((s) => s.libelle), ['Alimentation', 'Transport']);
      expect(boutique.total, -31000);
    });

    test('filtres catégories et contacts combinés ; vide = tous', () {
      final r = buildCustomReport(
        _transactions,
        ReportCriteria(
          debut: _septembre.debut,
          fin: _septembre.fin,
          categories: {'Alimentation', 'Transport'},
          contacts: {'Boutique'},
        ),
        ReportGrouping.categorieContact,
      );
      expect(r.groupes.map((g) => g.libelle), ['Alimentation', 'Transport']);
      expect(r.nombre, 3);
      expect(r.total, -31000);

      final inconnus = buildCustomReport(
        _transactions,
        ReportCriteria(debut: _septembre.debut, fin: _septembre.fin, contacts: {contactInconnu}),
        ReportGrouping.categorieContact,
      );
      expect(inconnus.nombre, 1);
    });
  });

  test('lignesCsvRapport : une ligne par transaction, dans l\'ordre du rapport', () {
    final r = buildCustomReport(
      _transactions,
      ReportCriteria(debut: _septembre.debut, fin: _septembre.fin, categories: {'Alimentation'}),
      ReportGrouping.categorieContact,
    );
    final lignes = ExportService.lignesCsvRapport(r);
    expect(lignes.first.take(3), ['Catégorie', 'Contact', 'Date']);
    expect(lignes.skip(1).map((l) => [l[0], l[1], l[4]]), [
      ['Alimentation', 'Boutique', -18000.0],
      ['Alimentation', 'Boutique', -12000.0],
      ['Alimentation', 'Marché', -18500.0],
    ]);
    expect(lignes[1][3], 'Paiement marchand');
  });
}
