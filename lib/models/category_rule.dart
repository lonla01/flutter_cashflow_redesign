/// Une règle de catégorisation apprise : quand un contact ou un mot-clé
/// donné est rencontré, on suggère automatiquement une catégorie.
class CategoryRule {
  final int? id;
  final String matchType; // 'contact_numero' | 'contact_nom_contains' | 'keyword'
  final String matchValue;
  final String categorie;

  CategoryRule({
    this.id,
    required this.matchType,
    required this.matchValue,
    required this.categorie,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'match_type': matchType,
        'match_value': matchValue,
        'categorie': categorie,
      };

  factory CategoryRule.fromMap(Map<String, Object?> map) => CategoryRule(
        id: map['id'] as int?,
        matchType: map['match_type'] as String,
        matchValue: map['match_value'] as String,
        categorie: map['categorie'] as String,
      );
}

/// Catégories proposées par défaut dans l'app.
const List<String> categoriesParDefaut = [
  'Alimentation',
  'Transport',
  'Télécom/Internet',
  'Logement',
  'Santé',
  'Loisirs',
  'Transferts personnels',
  'Retraits',
  'Revenus/Réceptions',
  'Autre',
];
