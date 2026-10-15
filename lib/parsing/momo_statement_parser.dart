import '../models/transaction.dart';

/// Un caractère d'une page de relevé, avec sa boîte englobante en
/// coordonnées PDF (origine en bas à gauche : `top` > `bottom`). Produit par
/// l'extraction PDF (voir MomoStatementImportService), dans l'ordre de
/// lecture du texte — espaces et retours à la ligne compris.
class StatementGlyph {
  const StatementGlyph({
    required this.page,
    required this.char,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int page;
  final String char;
  final double left;
  final double top;
  final double right;
  final double bottom;
}

/// Une ligne du tableau "Détails de la transaction" d'un relevé MTN MoMo
/// (export PDF de l'app MoMo).
class MomoStatementRow {
  const MomoStatementRow({
    required this.date,
    required this.typeLibelle,
    required this.aDe,
    required this.nomCompte,
    required this.montant,
    required this.idTransaction,
    required this.frais,
    required this.solde,
    required this.reference,
  });

  final DateTime date;

  /// Colonne "Type de paiement" (ex. "Utilisateur MoMo", "Débit", "Retrait").
  final String typeLibelle;

  /// Colonne "À/De" : numéro de téléphone ou code marchand/agent.
  final String aDe;
  final String nomCompte;

  /// Montant signé tel qu'imprimé : négatif pour un débit.
  final int montant;
  final String idTransaction;

  /// Frais + taxe.
  final double frais;
  final int solde;
  final String reference;
}

class MomoStatementParseResult {
  const MomoStatementParseResult({required this.rows, required this.balanceBreaks});

  /// Lignes dans l'ordre du relevé (la plus récente d'abord).
  final List<MomoStatementRow> rows;

  /// Nombre de paires de lignes consécutives dont les soldes ne
  /// s'enchaînent pas (solde précédent + montant - frais ≠ solde) : 0 sur un
  /// relevé complet et correctement lu. Sert de contrôle de cohérence.
  final int balanceBreaks;
}

const _mois = {
  'janv': 1, 'févr': 2, 'fevr': 2, 'mars': 3, 'avr': 4, 'mai': 5, 'juin': 6,
  'juil': 7, 'août': 8, 'aout': 8, 'sept': 9, 'oct': 10, 'nov': 11, 'déc': 12, 'dec': 12,
};

final _date = RegExp(r'^(\d{1,2}) ([^\s.]+)\.? (\d{4}) (\d{2}):(\d{2})$');

/// Mot reconstitué : suite de caractères non blancs consécutifs dans
/// l'ordre de lecture et sur une même ligne.
class _Word {
  _Word(this.page, this.left, this.y);
  final int page;
  final double left;

  /// Centre vertical du premier caractère alphanumérique (les boîtes des
  /// signes de ponctuation sont décalées verticalement).
  double y;
  bool yFromAlnum = false;
  final StringBuffer text = StringBuffer();
}

List<_Word> _words(List<StatementGlyph> glyphs) {
  final words = <_Word>[];
  _Word? cur;
  StatementGlyph? prev;
  final alnum = RegExp(r'[0-9A-Za-zÀ-ÿ]');
  for (final g in glyphs) {
    if (g.char.trim().isEmpty) {
      cur = null;
      prev = null;
      continue;
    }
    final mid = (g.top + g.bottom) / 2;
    final rupture = cur == null ||
        prev!.page != g.page ||
        g.left < prev.left ||
        g.left - prev.right > 3 ||
        (mid - (prev.top + prev.bottom) / 2).abs() > 3.5;
    if (rupture) {
      cur = _Word(g.page, g.left, mid);
      words.add(cur);
    }
    if (!cur.yFromAlnum && alnum.hasMatch(g.char)) {
      cur.y = mid;
      cur.yFromAlnum = true;
    }
    cur.text.write(g.char);
    prev = g;
  }
  return words;
}

/// Regroupe des mots en lignes (de haut en bas, puis de gauche à droite) et
/// les joint par des espaces.
String _texte(List<_Word> words) {
  final tries = [...words]..sort((a, b) => b.y.compareTo(a.y));
  final lignes = <List<_Word>>[];
  for (final w in tries) {
    if (lignes.isNotEmpty && (lignes.last.first.y - w.y).abs() <= 2.5) {
      lignes.last.add(w);
    } else {
      lignes.add([w]);
    }
  }
  return lignes
      .map((l) => (l..sort((a, b) => a.left.compareTo(b.left))).map((w) => w.text).join(' '))
      .join(' ')
      .trim();
}

enum _Col { date, type, aDe, nom, montant, id, frais, taxe, solde, ref }

/// Analyse un relevé MTN MoMo à partir des caractères positionnés de ses
/// pages. Les colonnes sont repérées par la position de leur en-tête sur
/// chaque page ; chaque mot est ensuite rattaché à la colonne sous laquelle
/// il commence et à la ligne de transaction dont la date est la plus proche
/// verticalement (les cellules multi-lignes sont centrées sur la date).
MomoStatementParseResult parseMomoStatement(List<StatementGlyph> glyphs) {
  final parPage = <int, List<_Word>>{};
  for (final w in _words(glyphs)) {
    (parPage[w.page] ??= []).add(w);
  }

  final rows = <MomoStatementRow>[];
  for (final page in parPage.keys.toList()..sort()) {
    final words = parPage[page]!;
    final montantHeader = words.where((w) => w.text.toString() == 'Montant').firstOrNull;
    if (montantHeader == null) continue;
    final hy = montantHeader.y;
    final enTete = words.where((w) => (w.y - hy).abs() <= 12).toList();
    double? x(bool Function(String) test) =>
        enTete.where((w) => test(w.text.toString())).firstOrNull?.left;
    final positions = {
      _Col.date: x((t) => t == 'Date'),
      _Col.type: x((t) => t == 'Type'),
      _Col.aDe: x((t) => t.startsWith('À/')),
      _Col.nom: x((t) => t == 'Nom'),
      _Col.montant: montantHeader.left,
      _Col.id: x((t) => t == 'ID'),
      _Col.frais: x((t) => t == 'Frais'),
      _Col.taxe: x((t) => t == 'Taxe'),
      _Col.solde: x((t) => t == 'Solde'),
      _Col.ref: x((t) => t.startsWith('Réf')),
    };
    if (positions.values.any((v) => v == null)) continue;
    final bornes = positions.entries.toList()..sort((a, b) => a.value!.compareTo(b.value!));
    // Les valeurs (montants notamment) peuvent commencer un peu avant le
    // début de leur en-tête.
    _Col colonne(double left) =>
        bornes.lastWhere((e) => e.value! <= left + 3, orElse: () => bornes.first).key;

    final corps = words.where((w) => w.y < hy - 12).toList();
    final parColonne = <_Col, List<_Word>>{};
    for (final w in corps) {
      (parColonne[colonne(w.left)] ??= []).add(w);
    }

    // Lignes d'ancrage : une date complète dans la colonne Date.
    final ancres = <(double, DateTime)>[];
    final datesParLigne = <double, List<_Word>>{};
    for (final w in parColonne[_Col.date] ?? const <_Word>[]) {
      final cle = datesParLigne.keys.where((y) => (y - w.y).abs() <= 2.5).firstOrNull ?? w.y;
      (datesParLigne[cle] ??= []).add(w);
    }
    for (final entry in datesParLigne.entries) {
      final m = _date.firstMatch(_texte(entry.value));
      final mois = m == null ? null : _mois[m.group(2)!.toLowerCase()];
      if (m == null || mois == null) continue;
      ancres.add((
        entry.key,
        DateTime(int.parse(m.group(3)!), mois, int.parse(m.group(1)!), int.parse(m.group(4)!),
            int.parse(m.group(5)!)),
      ));
    }
    ancres.sort((a, b) => b.$1.compareTo(a.$1));
    if (ancres.isEmpty) continue;

    final cellules = List.generate(ancres.length, (_) => <_Col, List<_Word>>{});
    for (final w in corps) {
      var meilleur = 0;
      for (var i = 1; i < ancres.length; i++) {
        if ((ancres[i].$1 - w.y).abs() < (ancres[meilleur].$1 - w.y).abs()) meilleur = i;
      }
      // Hors de toute ligne : pied de page, avertissement légal...
      if ((ancres[meilleur].$1 - w.y).abs() > 16) continue;
      (cellules[meilleur][colonne(w.left)] ??= []).add(w);
    }

    for (var i = 0; i < ancres.length; i++) {
      String cell(_Col c) => _texte(cellules[i][c] ?? const []);
      String chiffres(_Col c) => cell(c).replaceAll('FCFA', '').replaceAll(RegExp(r'\s'), '');
      final montant = int.tryParse(chiffres(_Col.montant).replaceAll('+', ''));
      final id = chiffres(_Col.id);
      final frais = double.tryParse(chiffres(_Col.frais)) ?? 0;
      final taxe = double.tryParse(chiffres(_Col.taxe)) ?? 0;
      final solde = int.tryParse(chiffres(_Col.solde));
      if (montant == null || solde == null || !RegExp(r'^\d{6,}$').hasMatch(id)) continue;
      rows.add(MomoStatementRow(
        date: ancres[i].$2,
        typeLibelle: cell(_Col.type),
        aDe: cell(_Col.aDe),
        nomCompte: cell(_Col.nom),
        montant: montant,
        idTransaction: id,
        frais: frais + taxe,
        solde: solde,
        reference: cell(_Col.ref),
      ));
    }
  }

  var breaks = 0;
  for (var i = 0; i + 1 < rows.length; i++) {
    final recente = rows[i];
    final precedente = rows[i + 1];
    if ((precedente.solde + recente.montant - recente.frais - recente.solde).abs() > 1) breaks++;
  }
  return MomoStatementParseResult(rows: rows, balanceBreaks: breaks);
}

/// Type de transaction de l'app correspondant à une ligne de relevé.
TransactionType momoStatementType(MomoStatementRow row) {
  final libelle = row.typeLibelle.toLowerCase();
  final entree = row.montant > 0;
  if (libelle.startsWith('utilisateur')) {
    return entree ? TransactionType.reception : TransactionType.transfertEnvoye;
  }
  // Avant "paiement" : "Paiement de facture ..." est un service, pas un
  // marchand.
  if (libelle.contains('facture')) return TransactionType.paiementService;
  if (libelle.startsWith('retrait')) return TransactionType.retrait;
  if (libelle.startsWith('encaisser')) return TransactionType.depotRecu;
  if (libelle.startsWith('paiement')) return TransactionType.paiementMarchand;
  if (libelle.contains('bank')) {
    return entree ? TransactionType.reception : TransactionType.transfertEnvoye;
  }
  // Débit (forfaits), factures, carte virtuelle...
  return entree ? TransactionType.reception : TransactionType.paiementService;
}

/// Convertit une ligne de relevé en transaction de l'app, avec les mêmes
/// conventions que le parsing des SMS MTN (lib/parsing/sms_parser.dart) :
/// même identifiant de transaction financière — donc une transaction déjà
/// importée depuis un SMS est reconnue comme doublon — et numéro de
/// contact en chiffres seuls.
MoneyTransaction momoStatementRowToTransaction(MomoStatementRow row) {
  final montant = row.montant.abs().toDouble();
  final entree = row.montant > 0;
  final numero = row.aDe.replaceAll(RegExp(r'[^0-9]'), '');
  final reference = row.reference.trim();
  return MoneyTransaction(
    source: TransactionSource.mtnMomo,
    type: momoStatementType(row),
    montant: montant,
    frais: row.frais,
    montantNet: entree ? montant : montant + row.frais,
    soldeApres: row.solde.toDouble(),
    contactNom: row.nomCompte.isEmpty ? null : row.nomCompte,
    contactNumero: numero.isEmpty ? null : numero,
    dateTransaction: row.date,
    idTransactionOperateur: row.idTransaction,
    notes: reference == '-' ? '' : reference,
  );
}
