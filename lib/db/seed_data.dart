import 'dart:math';

import '../models/transaction.dart';
import 'app_database.dart';

/// Génère et insère des transactions fictives réalistes, pour permettre de
/// démontrer les écrans de liste, d'édition et de rapports sans attendre de
/// vrais SMS. N'insère rien si la base contient déjà des transactions
/// (évite de dupliquer les données de démo à chaque lancement).
class SeedDataService {
  static final Random _rng = Random(42); // seed fixe = données reproductibles

  static const List<_Profil> _profils = [
    _Profil('SUPERMARCHE CASH AND CARRY', 'Alimentation', TransactionType.paiementMarchand, 2000, 25000),
    _Profil('BOULANGERIE DU CENTRE', 'Alimentation', TransactionType.paiementMarchand, 500, 5000),
    _Profil('MARCHE MOKOLO DETAIL', 'Alimentation', TransactionType.paiementMarchand, 1000, 15000),
    _Profil('TAXI MOTO EXPRESS', 'Transport', TransactionType.paiementMarchand, 200, 2000),
    _Profil('STATION TOTAL BONABERI', 'Transport', TransactionType.paiementMarchand, 3000, 20000),
    _Profil('MTN BUNDLES FORFAITS', 'Télécom/Internet', TransactionType.paiementService, 300, 5000),
    _Profil('ORANGE CREDIT RECHARGE', 'Télécom/Internet', TransactionType.paiementService, 300, 5000),
    _Profil('ENEO CAMEROUN SA', 'Logement', TransactionType.paiementMarchand, 5000, 40000),
    _Profil('CAMWATER FACTURE', 'Logement', TransactionType.paiementMarchand, 3000, 15000),
    _Profil('BAILLEUR FOTSO IMMEUBLE', 'Logement', TransactionType.transfertEnvoye, 50000, 150000),
    _Profil('PHARMACIE FRANCAISE', 'Santé', TransactionType.paiementMarchand, 1000, 20000),
    _Profil('CLINIQUE BONANJO', 'Santé', TransactionType.paiementMarchand, 5000, 60000),
    _Profil('RESTAURANT LE PALAIS', 'Loisirs', TransactionType.paiementMarchand, 2000, 15000),
    _Profil('CINEMA CANAL OLYMPIA', 'Loisirs', TransactionType.paiementMarchand, 2000, 8000),
    _Profil('KAMDEM JEAN', 'Transferts personnels', TransactionType.transfertEnvoye, 1000, 30000),
    _Profil('NGONO MARIE', 'Transferts personnels', TransactionType.transfertEnvoye, 1000, 20000),
    _Profil('FOKOU ALAIN', 'Transferts personnels', TransactionType.transfertEnvoye, 500, 10000),
    _Profil('AGENT ORANGE MONEY MOKOLO', 'Retraits', TransactionType.retrait, 5000, 100000),
    _Profil('AGENT MOMO AKWA', 'Retraits', TransactionType.retrait, 5000, 100000),
    _Profil('SALAIRE ENTREPRISE ALPHA SARL', 'Revenus/Réceptions', TransactionType.reception, 100000, 400000),
    _Profil('ATANGANA PAUL', 'Revenus/Réceptions', TransactionType.reception, 2000, 50000),
    _Profil('TCHOUBOU TIABOU', 'Revenus/Réceptions', TransactionType.depotRecu, 1000, 30000),
  ];

  static Future<void> semerSiVide(AppDatabase db) async {
    final count = await db.countTransactions();
    if (count > 0) return;
    final transactions = genererTransactionsFictives(nombre: 100);
    for (final tx in transactions) {
      await db.insertTransactionIfNew(tx);
    }
  }

  /// Génère une liste de transactions fictives réparties sur les ~90
  /// derniers jours, avec des montants, catégories et contacts variés,
  /// pour que les rapports hebdomadaires/mensuels aient un contenu
  /// significatif dès le premier lancement.
  static List<MoneyTransaction> genererTransactionsFictives({int nombre = 100}) {
    final maintenant = DateTime.now();
    final transactions = <MoneyTransaction>[];

    for (var i = 0; i < nombre; i++) {
      final profil = _profils[_rng.nextInt(_profils.length)];
      final joursAvant = _rng.nextInt(90);
      final date = maintenant.subtract(Duration(
        days: joursAvant,
        hours: _rng.nextInt(24),
        minutes: _rng.nextInt(60),
      ));
      final montant = (profil.montantMin +
              _rng.nextInt((profil.montantMax - profil.montantMin).toInt()))
          .toDouble();
      final double frais = profil.type == TransactionType.reception || profil.type == TransactionType.depotRecu
          ? 0.0
          : (montant * 0.005).roundToDouble().clamp(0, 500);
      final source = _rng.nextBool() ? TransactionSource.orangeMoney : TransactionSource.mtnMomo;

      transactions.add(MoneyTransaction(
        source: source,
        type: profil.type,
        montant: montant,
        frais: frais,
        contactNom: profil.contact,
        contactNumero: '6${70000000 + _rng.nextInt(9999999)}',
        categorie: profil.categorie,
        dateTransaction: date,
        idTransactionOperateur: 'SEED-${i.toString().padLeft(4, '0')}',
        soldeApres: null,
        smsBrut: null,
      ));
    }

    transactions.sort((a, b) => b.dateTransaction.compareTo(a.dateTransaction));
    return transactions;
  }
}

class _Profil {
  final String contact;
  final String categorie;
  final TransactionType type;
  final num montantMin;
  final num montantMax;

  const _Profil(this.contact, this.categorie, this.type, this.montantMin, this.montantMax);
}
