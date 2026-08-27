import '../db/app_database.dart';
import '../models/category_rule.dart';
import '../models/transaction.dart';

class CategorizationService {
  CategorizationService(this._db);
  final AppDatabase _db;

  /// Mots-clés par défaut détectés dans le nom du contact/marchand,
  /// utilisés seulement si aucune règle apprise ne correspond.
  static const Map<String, List<String>> _motsClesParCategorie = {
    'Télécom/Internet': ['bundle', 'forfait', 'momo bundles', 'orange', 'mtn', 'credit', 'internet'],
    'Alimentation': ['supermarche', 'market', 'boulangerie', 'restaurant', 'alimentation'],
    'Transport': ['taxi', 'moto', 'transport', 'carburant', 'station'],
    'Santé': ['pharmacie', 'clinique', 'hopital', 'medecin'],
    'Logement': ['loyer', 'bailleur', 'electricite', 'eneo', 'camwater', 'eau'],
  };

  Future<String> suggestCategory(MoneyTransaction tx) async {
    final rules = await _db.getCategoryRules();

    // 1) Règle apprise sur le numéro de contact exact.
    if (tx.contactNumero != null) {
      for (final r in rules) {
        if (r.matchType == 'contact_numero' && r.matchValue == tx.contactNumero) {
          return r.categorie;
        }
      }
    }
    // 2) Règle apprise sur un fragment du nom du contact.
    final nom = (tx.contactNom ?? '').toLowerCase();
    for (final r in rules) {
      if (r.matchType == 'contact_nom_contains' && nom.contains(r.matchValue.toLowerCase())) {
        return r.categorie;
      }
    }
    // 3) Catégorie par défaut selon le type de transaction.
    switch (tx.type) {
      case TransactionType.reception:
      case TransactionType.depotRecu:
        return 'Revenus/Réceptions';
      case TransactionType.retrait:
        return 'Retraits';
      case TransactionType.transfertEnvoye:
        return 'Transferts personnels';
      case TransactionType.paiementMarchand:
      case TransactionType.paiementService:
        break; // on tente les mots-clés ci-dessous
    }
    // 4) Mots-clés génériques dans le nom du marchand.
    for (final entry in _motsClesParCategorie.entries) {
      if (entry.value.any((mot) => nom.contains(mot))) {
        return entry.key;
      }
    }
    return 'Autre';
  }

  /// À appeler quand l'utilisateur corrige manuellement la catégorie d'une
  /// transaction : mémorise une règle pour les prochaines transactions du
  /// même contact.
  Future<void> learnFromCorrection(MoneyTransaction tx, String nouvelleCategorie) async {
    if (tx.contactNumero != null && tx.contactNumero!.isNotEmpty) {
      await _db.upsertCategoryRule(CategoryRule(
        matchType: 'contact_numero',
        matchValue: tx.contactNumero!,
        categorie: nouvelleCategorie,
      ));
    } else if (tx.contactNom != null && tx.contactNom!.isNotEmpty) {
      await _db.upsertCategoryRule(CategoryRule(
        matchType: 'contact_nom_contains',
        matchValue: tx.contactNom!,
        categorie: nouvelleCategorie,
      ));
    }
  }
}
