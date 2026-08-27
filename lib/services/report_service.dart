import '../models/transaction.dart';

class CategorieTotal {
  final String categorie;
  final double total; // valeur absolue dépensée dans cette catégorie
  CategorieTotal(this.categorie, this.total);
}

class ContactTotal {
  final String contact;
  final double total; // valeur absolue échangée avec ce contact
  ContactTotal(this.contact, this.total);
}

enum Periode { semaine, mois }

class ReportService {
  /// Renvoie le début de la période courante contenant [reference] selon
  /// [periode] (lundi pour la semaine, 1er du mois pour le mois).
  static DateTime debutPeriode(DateTime reference, Periode periode) {
    if (periode == Periode.semaine) {
      final lundi = reference.subtract(Duration(days: reference.weekday - 1));
      return DateTime(lundi.year, lundi.month, lundi.day);
    }
    return DateTime(reference.year, reference.month, 1);
  }

  static DateTime finPeriode(DateTime debut, Periode periode) {
    if (periode == Periode.semaine) {
      return debut.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
    }
    final moisSuivant = debut.month == 12
        ? DateTime(debut.year + 1, 1, 1)
        : DateTime(debut.year, debut.month + 1, 1);
    return moisSuivant.subtract(const Duration(milliseconds: 1));
  }

  static List<MoneyTransaction> filtrerParPeriode(
    List<MoneyTransaction> transactions,
    DateTime debut,
    DateTime fin,
  ) {
    return transactions
        .where((t) => !t.dateTransaction.isBefore(debut) && !t.dateTransaction.isAfter(fin))
        .toList();
  }

  /// Ne considère que les transactions "sortantes" pour les totaux de
  /// dépense (les entrées d'argent sont vues séparément).
  static bool estUneDepense(MoneyTransaction t) => t.montantSigne < 0;
  static bool estUneEntree(MoneyTransaction t) => t.montantSigne > 0;

  static List<CategorieTotal> totauxParCategorie(List<MoneyTransaction> transactions) {
    final map = <String, double>{};
    for (final t in transactions.where(estUneDepense)) {
      map[t.categorie] = (map[t.categorie] ?? 0) + t.montantNet;
    }
    final liste = map.entries.map((e) => CategorieTotal(e.key, e.value)).toList();
    liste.sort((a, b) => b.total.compareTo(a.total));
    return liste;
  }

  static List<ContactTotal> totauxParContact(List<MoneyTransaction> transactions) {
    final map = <String, double>{};
    for (final t in transactions) {
      final nom = t.contactNom?.trim();
      if (nom == null || nom.isEmpty) continue;
      map[nom] = (map[nom] ?? 0) + t.montantNet;
    }
    final liste = map.entries.map((e) => ContactTotal(e.key, e.value)).toList();
    liste.sort((a, b) => b.total.compareTo(a.total));
    return liste;
  }

  static double totalDepenses(List<MoneyTransaction> transactions) =>
      transactions.where(estUneDepense).fold(0.0, (s, t) => s + t.montantNet);

  static double totalEntrees(List<MoneyTransaction> transactions) => transactions
      .where((t) => t.montantSigne > 0)
      .fold(0.0, (s, t) => s + t.montant);
}
