import '../models/transaction.dart';

/// Ordre de regroupement d'un rapport personnalisé.
enum ReportGrouping { categorieContact, contactCategorie }

/// Libellé utilisé pour une transaction sans nom de contact.
const contactInconnu = 'Contact inconnu';

/// Nom de contact normalisé, tel qu'utilisé pour filtrer et regrouper.
String contactDe(MoneyTransaction t) {
  final nom = t.contactNom?.trim();
  return nom == null || nom.isEmpty ? contactInconnu : nom;
}

/// Critères d'un rapport personnalisé. Un ensemble vide de catégories ou
/// de contacts signifie "tous".
class ReportCriteria {
  const ReportCriteria({
    required this.debut,
    required this.fin,
    this.categories = const {},
    this.contacts = const {},
  });

  /// Bornes incluses.
  final DateTime debut;
  final DateTime fin;
  final Set<String> categories;
  final Set<String> contacts;

  bool retient(MoneyTransaction t) =>
      !t.dateTransaction.isBefore(debut) &&
      !t.dateTransaction.isAfter(fin) &&
      (categories.isEmpty || categories.contains(t.categorie)) &&
      (contacts.isEmpty || contacts.contains(contactDe(t)));
}

/// Sous-groupe : transactions d'un contact dans une catégorie (ou
/// l'inverse), de la plus ancienne à la plus récente.
class ReportSubGroup {
  ReportSubGroup(this.libelle, this.transactions);

  final String libelle;
  final List<MoneyTransaction> transactions;

  /// Solde net signé (voir MoneyTransaction.montantSigne).
  double get total => transactions.fold(0.0, (s, t) => s + t.montantSigne);
}

class ReportGroup {
  ReportGroup(this.libelle, this.sousGroupes);

  final String libelle;
  final List<ReportSubGroup> sousGroupes;

  double get total => sousGroupes.fold(0.0, (s, g) => s + g.total);
  int get nombre => sousGroupes.fold(0, (s, g) => s + g.transactions.length);
}

class CustomReport {
  CustomReport(this.criteres, this.regroupement, this.groupes);

  final ReportCriteria criteres;
  final ReportGrouping regroupement;
  final List<ReportGroup> groupes;

  Iterable<MoneyTransaction> get transactions =>
      groupes.expand((g) => g.sousGroupes).expand((s) => s.transactions);

  int get nombre => groupes.fold(0, (s, g) => s + g.nombre);
  double get total => groupes.fold(0.0, (s, g) => s + g.total);
  double get depense =>
      transactions.where((t) => t.montantSigne < 0).fold(0.0, (s, t) => s - t.montantSigne);
  double get recu =>
      transactions.where((t) => t.montantSigne > 0).fold(0.0, (s, t) => s + t.montantSigne);
}

/// Construit un rapport : filtre [transactions] selon [criteres], puis les
/// regroupe sur deux niveaux selon [regroupement]. Groupes et sous-groupes
/// sont triés par importance (valeur absolue du total, puis libellé) ;
/// les transactions de chaque sous-groupe par ordre chronologique.
CustomReport buildCustomReport(
  List<MoneyTransaction> transactions,
  ReportCriteria criteres,
  ReportGrouping regroupement,
) {
  final cle1 = regroupement == ReportGrouping.categorieContact
      ? (MoneyTransaction t) => t.categorie
      : contactDe;
  final cle2 = regroupement == ReportGrouping.categorieContact
      ? contactDe
      : (MoneyTransaction t) => t.categorie;

  final arbre = <String, Map<String, List<MoneyTransaction>>>{};
  for (final t in transactions.where(criteres.retient)) {
    ((arbre[cle1(t)] ??= {})[cle2(t)] ??= []).add(t);
  }

  int parImportance(String la, double ta, String lb, double tb) {
    final c = tb.abs().compareTo(ta.abs());
    return c != 0 ? c : la.compareTo(lb);
  }

  final groupes = arbre.entries.map((g) {
    final sous = g.value.entries
        .map((s) => ReportSubGroup(
              s.key,
              s.value..sort((a, b) => a.dateTransaction.compareTo(b.dateTransaction)),
            ))
        .toList()
      ..sort((a, b) => parImportance(a.libelle, a.total, b.libelle, b.total));
    return ReportGroup(g.key, sous);
  }).toList()
    ..sort((a, b) => parImportance(a.libelle, a.total, b.libelle, b.total));

  return CustomReport(criteres, regroupement, groupes);
}
