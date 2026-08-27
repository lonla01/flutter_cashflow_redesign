import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_tracker/models/transaction.dart';
import 'package:mobile_money_tracker/parsing/sms_parser.dart';

void main() {
  group('Orange Money — messages à traiter', () {
    test('Transfert envoyé', () {
      const sms = 'Transfert de 690000001 KAMDEM JEAN vers 691000002 NGONO MARIE '
          'reussi. ID transaction: PP260818.1415.B80927, Montant Transaction: 10000 FCFA, '
          'Frais: 24 FCFA, Commission: 0 FCFA, Montant Net: 10024 FCFA, '
          'Nouveau Solde: 2502.88 FCFA.';
      final tx = parseOrangeMoney(sms);
      expect(tx, isNotNull);
      expect(tx!.type, TransactionType.transfertEnvoye);
      expect(tx.montant, 10000);
      expect(tx.frais, 24);
      expect(tx.montantNet, 10024);
      expect(tx.soldeApres, 2502.88);
      expect(tx.contactNom, 'NGONO MARIE');
      expect(tx.idTransactionOperateur, 'PP260818.1415.B80927');
      expect(tx.dateTransaction, DateTime(2026, 8, 18, 14, 15));
    });

    test('Dépôt reçu', () {
      const sms = 'Depot effectue par 658000003 ATANGANA PAUL to 697000004 FOKOU ALAIN. '
          'Informations detaillees: Montant de transaction : 5000 FCFA, '
          'ID transaction : CI260806.1234.C85874, Frais : 0 FCFA, Commission : 0 FCFA, '
          'Montant Net du Credit : 5000 FCFA, Nouveau Solde : 5031.88 FCFA.';
      final tx = parseOrangeMoney(sms);
      expect(tx, isNotNull);
      expect(tx!.type, TransactionType.depotRecu);
      expect(tx.montant, 5000);
      expect(tx.contactNom, 'ATANGANA PAUL');
      expect(tx.soldeApres, 5031.88);
    });

    test('Paiement de service (forfait)', () {
      const sms = "Felicitations, vous venez d'effectuer un payement de 300 FCFA "
          'pour 300U = 850 Mo/3J. N° de transaction : MP260802.0716.D80550. '
          'Nouveau solde : 31.88 FCFA. Plus de service au #150#';
      final tx = parseOrangeMoney(sms);
      expect(tx, isNotNull);
      expect(tx!.type, TransactionType.paiementService);
      expect(tx.montant, 300);
      expect(tx.soldeApres, 31.88);
    });

    test('Retrait', () {
      const sms = 'Retrait d\'argent reussi par le 686000005 avec le Code : 1020995. '
          'Informations detaillees : Montant: 1000 FCFA, Frais: 54 FCFA, '
          'No de transaction CO260730.2056.B49224, montant net debite 1054 FCFA, '
          'Nouveau solde: 2044.57 FCFA.';
      final tx = parseOrangeMoney(sms);
      expect(tx, isNotNull);
      expect(tx!.type, TransactionType.retrait);
      expect(tx.montant, 1000);
      expect(tx.montantNet, 1054);
    });
  });

  group('Orange Money — messages à ignorer', () {
    test('Lien de correction de transaction (promo)', () {
      const sms = 'Erreur de frappe ? Ca se rattrape ! Desormais si tu te trompes '
          'de montant ou de destinataire, annule vite via #150*15# ou MAX IT avant '
          'que l\'argent ne soit utilise. https://maxit-link.com/cm/id=abc123';
      expect(parseOrangeMoney(sms), isNull);
    });

    test('Consultation de solde seule', () {
      const sms = 'Le solde de votre compte est de 331.88 FCFA.';
      expect(parseOrangeMoney(sms), isNull);
    });
  });

  group('MTN Mobile Money — messages à traiter', () {
    test('Paiement marchand finalisé (avec texte promo à ignorer)', () {
      const sms = 'Votre paiement de 5000 XAF a BOUTIQUE EXEMPLE (237600000001) '
          'a ete finalise a 2026-08-19 10:11:51. Message : . '
          'Votre nouveau solde : 287471 XAF. Les frais s\'elevaient a 0 XAF. '
          'Le montant faisait l\'objet d\'une reduction de 0 XAF et de coupons '
          'd\'une valeur de . Identifiant de transaction financiere : 18410741470. '
          'ID de transaction externe : -. }. Grande promo MoMo, tape *126*6#.';
      final tx = parseMtnMomo(sms);
      expect(tx, isNotNull);
      expect(tx!.type, TransactionType.paiementMarchand);
      expect(tx.montant, 5000);
      expect(tx.soldeApres, 287471);
      expect(tx.idTransactionOperateur, '18410741470');
      expect(tx.dateTransaction, DateTime(2026, 8, 19, 10, 11, 51));
      // Le texte promotionnel après l'ID de transaction externe ne doit pas
      // polluer les champs extraits.
      expect(tx.contactNom, 'BOUTIQUE EXEMPLE');
    });

    test('Retrait', () {
      const sms = 'Vous avez effectue avec succes le retrait de 5000 FCFA de '
          'votre compte mobile money  chez AGENT EXEMPLE le 2026-08-18 17:34:10. '
          'Votre nouveau solde est de:292471 FCFA. Transaction Id: 18403066742.';
      final tx = parseMtnMomo(sms);
      expect(tx, isNotNull);
      expect(tx!.type, TransactionType.retrait);
      expect(tx.montant, 5000);
      expect(tx.contactNom, 'AGENT EXEMPLE');
    });

    test('Transfert envoyé avec référence', () {
      const sms = 'Transfert de 3054 FCFA effectue avec succes a KEVIN EXEMPLE '
          '(237600000002) le 2026-08-17 14:58:21. FRAIS 10 FCFA. '
          'transaction Id: 18387577522. Reference: Ventilateur. '
          'Nouveau solde est: 314756 FCFA.';
      final tx = parseMtnMomo(sms);
      expect(tx, isNotNull);
      expect(tx!.type, TransactionType.transfertEnvoye);
      expect(tx.montant, 3054);
      expect(tx.frais, 10);
      expect(tx.notes, contains('Ventilateur'));
    });

    test('Réception d\'argent', () {
      const sms = 'Vous avez recu 45000 XAF de MARLYSE EXEMPLE (237600000003) '
          'sur votre compte mobile money à 2026-07-01 15:50:19. '
          'Message de l\'expéditeur: 1. Votre nouveau solde: 121141 XAF. '
          'FRAIS: FCFA 0. Financial Transaction Id: 17756291343.';
      final tx = parseMtnMomo(sms);
      expect(tx, isNotNull);
      expect(tx!.type, TransactionType.reception);
      expect(tx.montant, 45000);
      expect(tx.contactNom, 'MARLYSE EXEMPLE');
    });
  });

  group('MTN Mobile Money — messages à ignorer', () {
    test('Code OTP', () {
      const sms = '<#> Y\'ello. Entrez le code suivant:2685 pour completer votre '
          'login. Soyez prudent. NE PARTAGEZ PAS ce code.';
      expect(parseMtnMomo(sms), isNull);
    });

    test('Confirmation secondaire sans référence de transaction', () {
      const sms = 'Paiement Successintegral de 1000 a CAISSE EXEMPLE 237600000004. '
          'Merci d\'utiliser MTN MoMo.';
      expect(parseMtnMomo(sms), isNull);
    });
  });

  test('parseSms() essaie Orange puis MTN', () {
    const smsOrange = 'Le solde de votre compte est de 100 FCFA.';
    expect(parseSms(smsOrange), isNull);
  });
}
