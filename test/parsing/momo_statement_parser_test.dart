// Relevé MTN MoMo synthétique (données fictives) reproduisant la mise en
// page de l'export PDF de l'app MoMo : en-têtes de colonnes, cellules sur
// plusieurs lignes centrées sur la date, FCFA sous les montants, mentions
// légales en pied de page.

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_tracker/db/app_database.dart';
import 'package:mobile_money_tracker/models/transaction.dart';
import 'package:mobile_money_tracker/parsing/momo_statement_parser.dart';
import 'package:mobile_money_tracker/services/categorization_service.dart';
import 'package:mobile_money_tracker/services/momo_statement_import_service.dart';

import '../support/sample_transaction.dart';

/// Place [texte] à partir de ([x], [y]) (y = centre vertical), un
/// caractère de 3 points de large, suivi d'un saut de ligne — comme le
/// texte extrait par PDFium, espaces compris.
void _ecrire(List<StatementGlyph> out, int page, double x, double y, String texte) {
  for (var i = 0; i < texte.length; i++) {
    // Comme dans les vrais relevés, la boîte d'un signe de ponctuation est
    // décalée verticalement.
    final dy = '.-_'.contains(texte[i]) ? -2.5 : 0.0;
    out.add(StatementGlyph(
      page: page,
      char: texte[i],
      left: x + i * 3,
      right: x + i * 3 + 2.6,
      top: y + dy + 2,
      bottom: y + dy - 2,
    ));
  }
  out.add(StatementGlyph(page: page, char: '\n', left: x, right: x, top: y, bottom: y));
}

void _enTete(List<StatementGlyph> g, int page) {
  _ecrire(g, page, 42, 578, 'Date et');
  _ecrire(g, page, 42, 568, 'heure');
  _ecrire(g, page, 110, 578, 'Type de');
  _ecrire(g, page, 111, 568, 'paiement');
  _ecrire(g, page, 168, 573, 'À/De');
  _ecrire(g, page, 217, 578, 'Nom du');
  _ecrire(g, page, 217, 568, 'Compte');
  _ecrire(g, page, 291, 573, 'Montant');
  _ecrire(g, page, 341, 578, 'ID de');
  _ecrire(g, page, 341, 568, 'Transaction');
  _ecrire(g, page, 396, 573, 'Frais');
  _ecrire(g, page, 437, 573, 'Taxe');
  _ecrire(g, page, 471, 573, 'Solde');
  _ecrire(g, page, 515, 573, 'Référence');
}

/// Une ligne de transaction centrée sur [y] ; [haut]/[bas] : lignes de
/// chaque colonne au-dessus/au-dessous de la date.
void _ligne(
  List<StatementGlyph> g,
  int page,
  double y, {
  required String date,
  required List<String> type,
  List<String> aDe = const [],
  required List<String> nom,
  required String montant,
  required String id,
  required String frais,
  required String solde,
  required String ref,
}) {
  void colonne(double x, List<String> lignes) {
    final debut = y + (lignes.length - 1) * 3.5;
    for (var i = 0; i < lignes.length; i++) {
      _ecrire(g, page, x, debut - i * 7, lignes[i]);
    }
  }

  _ecrire(g, page, 42, y, date);
  colonne(111, type);
  colonne(168, aDe);
  colonne(217, nom);
  _ecrire(g, page, 290, y, montant);
  _ecrire(g, page, 341, y, id);
  colonne(396, [frais, 'FCFA']);
  colonne(437, ['0.00', 'FCFA']);
  colonne(471, [solde, 'FCFA']);
  _ecrire(g, page, 515, y, ref);
}

List<StatementGlyph> _releve({String soldeLigneB = '16370'}) {
  final g = <StatementGlyph>[];
  _ecrire(g, 1, 32, 604, 'Détails de la transaction');
  _ecrire(g, 1, 454, 604, 'Solde Disponible: 15310 FCFA');
  _enTete(g, 1);
  _ligne(g, 1, 545,
      date: '14 oct. 2026 13:23',
      type: ['Utilisateur', 'MoMo'],
      aDe: ['+237 67 11', '22 33 4'],
      nom: ['JEAN', 'DUPONT'],
      montant: '-1054',
      id: '19200000001',
      frais: '6.00',
      solde: '15310',
      ref: 'Loyer');
  _ligne(g, 1, 514,
      date: '13 oct. 2026 08:23',
      type: ['Débit'],
      nom: ['MTNC', 'BUNDLES_FORFAITS'],
      montant: '-1000',
      id: '19200000002',
      frais: '0.00',
      solde: soldeLigneB,
      ref: '200129');
  _ligne(g, 1, 483,
      date: '2 sept. 2026 07:05',
      type: ['Utilisateur', 'MoMo'],
      aDe: ['+237 68 55', '66 77 8'],
      nom: ['MARIE', 'NGONO'],
      montant: '+5000',
      id: '19200000003',
      frais: '0.00',
      solde: '17370',
      ref: '-');
  _ecrire(g, 1, 32, 60, 'Avis de non-responsabilité 2026 12:00 -500 19999999999');
  _enTete(g, 2);
  _ligne(g, 2, 545,
      date: '18 juil. 2026 12:20',
      type: ['Paiement de', 'facture', 'electricity'],
      aDe: ['880000001'],
      nom: ['ENEO'],
      montant: '-4750',
      id: '19200000004',
      frais: '100.00',
      solde: '12370',
      ref: 'E_Bills');
  return g;
}

void main() {
  group('parseMomoStatement', () {
    test('lit chaque ligne, colonnes multi-lignes comprises, sur toutes les pages', () {
      final res = parseMomoStatement(_releve());

      expect(res.rows.map((r) => r.idTransaction),
          ['19200000001', '19200000002', '19200000003', '19200000004']);
      expect(res.balanceBreaks, 0);

      final a = res.rows[0];
      expect(a.date, DateTime(2026, 10, 14, 13, 23));
      expect(a.typeLibelle, 'Utilisateur MoMo');
      expect(a.aDe, '+237 67 11 22 33 4');
      expect(a.nomCompte, 'JEAN DUPONT');
      expect(a.montant, -1054);
      expect(a.frais, 6.0);
      expect(a.solde, 15310);
      expect(a.reference, 'Loyer');

      expect(res.rows[1].nomCompte, 'MTNC BUNDLES_FORFAITS');
      expect(res.rows[2].date, DateTime(2026, 9, 2, 7, 5));
      expect(res.rows[2].montant, 5000);
      expect(res.rows[3].typeLibelle, 'Paiement de facture electricity');
      expect(res.rows[3].frais, 100.0);
    });

    test('signale des soldes qui ne s\'enchaînent pas', () {
      final res = parseMomoStatement(_releve(soldeLigneB: '16000'));
      expect(res.rows, hasLength(4));
      expect(res.balanceBreaks, 2);
    });

    test('un document sans tableau de relevé ne donne aucune ligne', () {
      final g = <StatementGlyph>[];
      _ecrire(g, 1, 40, 700, 'Facture du 14 oct. 2026 13:23 montant 1000');
      expect(parseMomoStatement(g).rows, isEmpty);
    });
  });

  group('momoStatementRowToTransaction', () {
    final rows = parseMomoStatement(_releve()).rows;

    test('transfert envoyé : frais ajoutés au montant net, numéro en chiffres', () {
      final tx = momoStatementRowToTransaction(rows[0]);
      expect(tx.source, TransactionSource.mtnMomo);
      expect(tx.type, TransactionType.transfertEnvoye);
      expect(tx.montant, 1054);
      expect(tx.montantNet, 1060);
      expect(tx.contactNumero, '237671122334');
      expect(tx.contactNom, 'JEAN DUPONT');
      expect(tx.idTransactionOperateur, '19200000001');
      expect(tx.soldeApres, 15310);
      expect(tx.notes, 'Loyer');
    });

    test('types : forfait, réception, facture', () {
      expect(momoStatementRowToTransaction(rows[1]).type, TransactionType.paiementService);
      final reception = momoStatementRowToTransaction(rows[2]);
      expect(reception.type, TransactionType.reception);
      expect(reception.montantNet, 5000);
      expect(reception.notes, '');
      expect(momoStatementRowToTransaction(rows[3]).type, TransactionType.paiementService);
    });
  });

  group('MomoStatementImportService', () {
    late AppDatabase db;
    late MomoStatementImportService service;

    setUp(() {
      db = AppDatabase.withExecutor(NativeDatabase.memory());
      service = MomoStatementImportService(
        db,
        CategorizationService(db),
        extractor: (_) async => _releve(),
      );
    });

    tearDown(() => db.close());

    test('importe, puis ignore les doublons à la réimportation', () async {
      // Déjà connue via un SMS : même identifiant de transaction MTN.
      await db.insertTransactionIfNew(buildTransaction(idTransactionOperateur: '19200000002'));

      final premier = await service.importer(Uint8List(0));
      expect(premier.lues, 4);
      expect(premier.importees, 3);
      expect(premier.dejaPresentes, 1);
      expect(premier.debut, DateTime(2026, 7, 18, 12, 20));
      expect(premier.fin, DateTime(2026, 10, 14, 13, 23));
      expect(await db.countTransactions(), 4);

      final second = await service.importer(Uint8List(0));
      expect(second.importees, 0);
      expect(await db.countTransactions(), 4);
    });

    test('catégorise et met en file de synchronisation', () async {
      await service.importer(Uint8List(0));
      final txs = await db.getAllTransactions();
      final reception = txs.firstWhere((t) => t.idTransactionOperateur == '19200000003');
      expect(reception.categorie, 'Revenus/Réceptions');
      expect(await db.getSyncableEntries(), hasLength(4));
    });

    test('refuse un fichier qui n\'est pas un relevé', () async {
      final autre = MomoStatementImportService(db, CategorizationService(db),
          extractor: (_) async => const []);
      expect(() => autre.importer(Uint8List(0)), throwsA(isA<MomoStatementFormatException>()));
    });
  });
}
