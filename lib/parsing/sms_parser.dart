import '../models/transaction.dart';

/// Résultat interne neutre avant transformation en [MoneyTransaction],
/// pour garder le parsing testable indépendamment du modèle final.
class _Champs {
  final double montant;
  final double frais;
  final double? montantNet;
  final double? solde;
  final String? contactNom;
  final String? contactNumero;
  final String idTransaction;
  final DateTime date;

  _Champs({
    required this.montant,
    this.frais = 0,
    this.montantNet,
    this.solde,
    this.contactNom,
    this.contactNumero,
    required this.idTransaction,
    required this.date,
  });
}

double _num(String s) => double.parse(s.replaceAll(',', '.').trim());

/// Extrait la date embarquée dans un identifiant de transaction Orange
/// Money, au format {2 lettres}{YYMMDD}.{HHMM}.{...} (ex: PP260818.1415.B80927).
/// Retourne `null` si le format n'est pas reconnu (on utilisera alors la date
/// de réception du SMS comme repli).
DateTime? extraireDateDepuisIdOrange(String idTransaction) {
  final m = RegExp(r'^[A-Z]{2}(\d{2})(\d{2})(\d{2})\.(\d{2})(\d{2})\.')
      .firstMatch(idTransaction);
  if (m == null) return null;
  final annee = 2000 + int.parse(m.group(1)!);
  final mois = int.parse(m.group(2)!);
  final jour = int.parse(m.group(3)!);
  final heure = int.parse(m.group(4)!);
  final minute = int.parse(m.group(5)!);
  return DateTime(annee, mois, jour, heure, minute);
}

DateTime _parseDateMtn(String brut) {
  final normalise = brut.trim().replaceFirst(' ', 'T');
  return DateTime.parse(normalise);
}

/// Messages à ignorer explicitement, quel que soit l'opérateur : codes OTP,
/// promotions, consultations de solde seules, confirmations dupliquées sans
/// référence de transaction.
bool estUnMessageAIgnorer(String body) {
  final b = body.trim();
  if (b.contains('maxit-link.com')) return true;
  if (RegExp(r'^Le solde de votre compte est de [\d.,]+\s*FCFA\.?$').hasMatch(b)) {
    return true;
  }
  if (b.contains('Entrez le code suivant') || b.contains('NE PARTAGEZ PAS')) {
    return true;
  }
  // Confirmation secondaire MTN sans ID de transaction ni solde.
  if (RegExp(r'^Paiement Success').hasMatch(b) &&
      !b.contains('Transaction Id') &&
      !b.contains('Identifiant de transaction')) {
    return true;
  }
  return false;
}

// ---------------------------------------------------------------------
// Orange Money
// ---------------------------------------------------------------------

MoneyTransaction? _parseOrangeTransfertEnvoye(String b) {
  final m = RegExp(
    r'Transfert de (\d+)\s+(.+?)\s+vers (\d+)\s+(.+?)\s+reussi\.\s*'
    r'ID transaction:\s*([\w.]+),\s*Montant Transaction:\s*([\d.,]+)\s*FCFA,\s*'
    r'Frais:\s*([\d.,]+)\s*FCFA,\s*Commission:\s*([\d.,]+)\s*FCFA,\s*'
    r'Montant Net:\s*([\d.,]+)\s*FCFA,\s*Nouveau Solde:\s*([\d.,]+)\s*FCFA\.',
  ).firstMatch(b);
  if (m == null) return null;
  final idTx = m.group(5)!;
  return MoneyTransaction(
    source: TransactionSource.orangeMoney,
    type: TransactionType.transfertEnvoye,
    montant: _num(m.group(6)!),
    frais: _num(m.group(7)!),
    montantNet: _num(m.group(9)!),
    soldeApres: _num(m.group(10)!),
    contactNom: m.group(4)!.trim(),
    contactNumero: m.group(3),
    idTransactionOperateur: idTx,
    dateTransaction: extraireDateDepuisIdOrange(idTx) ?? DateTime.now(),
    smsBrut: b,
  );
}

MoneyTransaction? _parseOrangeDepotRecu(String b) {
  final m = RegExp(
    r'Depot effectue par (\d+)\s+(.+?)\s+to (\d+)\s+(.+?)\.\s*'
    r'Informations detaillees:\s*Montant de transaction\s*:\s*([\d.,]+)\s*FCFA,\s*'
    r'ID transaction\s*:\s*([\w.]+),\s*Frais\s*:\s*([\d.,]+)\s*FCFA,\s*'
    r'Commission\s*:\s*([\d.,]+)\s*FCFA,\s*Montant Net du Credit\s*:\s*([\d.,]+)\s*FCFA,\s*'
    r'Nouveau Solde\s*:\s*([\d.,]+)\s*FCFA\.',
  ).firstMatch(b);
  if (m == null) return null;
  final idTx = m.group(6)!;
  return MoneyTransaction(
    source: TransactionSource.orangeMoney,
    type: TransactionType.depotRecu,
    montant: _num(m.group(5)!),
    frais: _num(m.group(7)!),
    montantNet: _num(m.group(9)!),
    soldeApres: _num(m.group(10)!),
    contactNom: m.group(2)!.trim(),
    contactNumero: m.group(1),
    idTransactionOperateur: idTx,
    dateTransaction: extraireDateDepuisIdOrange(idTx) ?? DateTime.now(),
    smsBrut: b,
  );
}

MoneyTransaction? _parseOrangePaiementService(String b) {
  final m = RegExp(
    r"Felicitations, vous venez d'effectuer un payement de ([\d.,]+)\s*FCFA pour (.+?)\.\s*"
    r'N° de transaction\s*:\s*([\w.]+)\.\s*Nouveau solde\s*:\s*([\d.,]+)\s*FCFA\.',
  ).firstMatch(b);
  if (m == null) return null;
  final idTx = m.group(3)!;
  return MoneyTransaction(
    source: TransactionSource.orangeMoney,
    type: TransactionType.paiementService,
    montant: _num(m.group(1)!),
    soldeApres: _num(m.group(4)!),
    contactNom: m.group(2)!.trim(),
    idTransactionOperateur: idTx,
    dateTransaction: extraireDateDepuisIdOrange(idTx) ?? DateTime.now(),
    smsBrut: b,
  );
}

MoneyTransaction? _parseOrangeRetrait(String b) {
  final m = RegExp(
    r"Retrait d'argent reussi par le (\d+)\s+avec le Code\s*:\s*(\d+)\.\s*"
    r'Informations detaillees\s*:\s*Montant:\s*([\d.,]+)\s*FCFA,\s*Frais:\s*([\d.,]+)\s*FCFA,\s*'
    r'No de transaction\s+([\w.]+),\s*montant net debite\s*([\d.,]+)\s*FCFA,\s*'
    r'Nouveau solde:\s*([\d.,]+)\s*FCFA\.',
  ).firstMatch(b);
  if (m == null) return null;
  final idTx = m.group(5)!;
  return MoneyTransaction(
    source: TransactionSource.orangeMoney,
    type: TransactionType.retrait,
    montant: _num(m.group(3)!),
    frais: _num(m.group(4)!),
    montantNet: _num(m.group(6)!),
    soldeApres: _num(m.group(7)!),
    contactNumero: m.group(1),
    idTransactionOperateur: idTx,
    dateTransaction: extraireDateDepuisIdOrange(idTx) ?? DateTime.now(),
    smsBrut: b,
  );
}

MoneyTransaction? parseOrangeMoney(String body) {
  final b = body.trim();
  if (estUnMessageAIgnorer(b)) return null;
  return _parseOrangeTransfertEnvoye(b) ??
      _parseOrangeDepotRecu(b) ??
      _parseOrangePaiementService(b) ??
      _parseOrangeRetrait(b);
}

// ---------------------------------------------------------------------
// MTN Mobile Money
// ---------------------------------------------------------------------

MoneyTransaction? _parseMtnPaiementMarchand(String b) {
  final m = RegExp(
    r'Votre paiement de ([\d.,]+)\s*XAF a (.+?)\s*\((\d+)\)\s*a ete finalise a ([\d\-: ]+?)\.'
    r'.*?Votre nouveau solde\s*:\s*([\d.,]+)\s*XAF\.'
    r'.*?Les frais s\x27elevaient a ([\d.,]+)\s*XAF\.'
    r'.*?Identifiant de transaction financiere\s*:\s*(\d+)\.',
    dotAll: true,
  ).firstMatch(b);
  if (m == null) return null;
  return MoneyTransaction(
    source: TransactionSource.mtnMomo,
    type: TransactionType.paiementMarchand,
    montant: _num(m.group(1)!),
    frais: _num(m.group(6)!),
    montantNet: _num(m.group(1)!) + _num(m.group(6)!),
    soldeApres: _num(m.group(5)!),
    contactNom: m.group(2)!.trim(),
    contactNumero: m.group(3),
    idTransactionOperateur: m.group(7),
    dateTransaction: _parseDateMtn(m.group(4)!),
    smsBrut: b,
  );
}

MoneyTransaction? _parseMtnTransactionGenerique(String b) {
  final m = RegExp(
    r"Une transaction de ([\d.,]+)\s*XAF effectuee par (.+?)\s*\(([\w.]+)\)\s*"
    r"sur votre compte d'argent mobile s'est terminee avec succes a ([\d\-: ]+?)\."
    r'.*?Votre nouveau solde\s*:\s*([\d.,]+)\s*XAF\.'
    r'.*?Les frais s\x27elevaient a ([\d.,]+)\s*'
    r'.*?Identifiant de transaction financiere\s*:\s*(\d+)\.',
    dotAll: true,
  ).firstMatch(b);
  if (m == null) return null;
  return MoneyTransaction(
    source: TransactionSource.mtnMomo,
    type: TransactionType.paiementMarchand,
    montant: _num(m.group(1)!),
    frais: _num(m.group(6)!),
    montantNet: _num(m.group(1)!) + _num(m.group(6)!),
    soldeApres: _num(m.group(5)!),
    contactNom: m.group(2)!.trim(),
    contactNumero: m.group(3),
    idTransactionOperateur: m.group(7),
    dateTransaction: _parseDateMtn(m.group(4)!),
    smsBrut: b,
  );
}

MoneyTransaction? _parseMtnRetrait(String b) {
  final m = RegExp(
    r'Vous avez effectue avec succes le retrait de ([\d.,]+)\s*FCFA de votre compte mobile money\s+'
    r'chez (.+?)\s+le ([\d\-: ]+?)\.\s*Votre nouveau solde est de\s*:\s*([\d.,]+)\s*FCFA\.\s*'
    r'Transaction Id:\s*(\d+)\.',
  ).firstMatch(b);
  if (m == null) return null;
  return MoneyTransaction(
    source: TransactionSource.mtnMomo,
    type: TransactionType.retrait,
    montant: _num(m.group(1)!),
    montantNet: _num(m.group(1)!),
    soldeApres: _num(m.group(4)!),
    contactNom: m.group(2)!.trim(),
    idTransactionOperateur: m.group(5),
    dateTransaction: _parseDateMtn(m.group(3)!),
    smsBrut: b,
  );
}

MoneyTransaction? _parseMtnTransfertEnvoye(String b) {
  final m = RegExp(
    r'Transfert de ([\d.,]+)\s*FCFA effectue avec succes a (.+?)\s*\((\d+)\)\s*le ([\d\-: ]+?)\.\s*'
    r'FRAIS\s*([\d.,]+)\s*FCFA\.\s*transaction Id:\s*(\d+)\.\s*'
    r'Reference:\s*(.*?)\.\s*Nouveau solde est:\s*([\d.,]+)\s*FCFA\.',
  ).firstMatch(b);
  if (m == null) return null;
  return MoneyTransaction(
    source: TransactionSource.mtnMomo,
    type: TransactionType.transfertEnvoye,
    montant: _num(m.group(1)!),
    frais: _num(m.group(5)!),
    montantNet: _num(m.group(1)!) + _num(m.group(5)!),
    soldeApres: _num(m.group(8)!),
    contactNom: m.group(2)!.trim(),
    contactNumero: m.group(3),
    idTransactionOperateur: m.group(6),
    dateTransaction: _parseDateMtn(m.group(4)!),
    notes: m.group(7)!.trim().isEmpty ? '' : 'Référence: ${m.group(7)!.trim()}',
    smsBrut: b,
  );
}

MoneyTransaction? _parseMtnReception(String b) {
  final m = RegExp(
    r'Vous avez recu ([\d.,]+)\s*XAF de (.+?)\s*\((\d+)\)\s*sur votre compte mobile money.*?'
    r'à ([\d\-: ]+?)\.\s*Message de l\x27exp[ée]diteur\s*:\s*(.*?)\.\s*'
    r'Votre nouveau solde\s*:\s*([\d.,]+)\s*XAF\.\s*FRAIS\s*:\s*FCFA\s*([\d.,]+)\.\s*'
    r'Financial Transaction Id\s*:\s*(\d+)\.',
    dotAll: true,
  ).firstMatch(b);
  if (m == null) return null;
  final message = m.group(5)!.trim();
  return MoneyTransaction(
    source: TransactionSource.mtnMomo,
    type: TransactionType.reception,
    montant: _num(m.group(1)!),
    frais: _num(m.group(7)!),
    montantNet: _num(m.group(1)!),
    soldeApres: _num(m.group(6)!),
    contactNom: m.group(2)!.trim(),
    contactNumero: m.group(3),
    idTransactionOperateur: m.group(8),
    dateTransaction: _parseDateMtn(m.group(4)!),
    notes: message.isEmpty || message == 'null' ? '' : message,
    smsBrut: b,
  );
}

MoneyTransaction? parseMtnMomo(String body) {
  final b = body.trim();
  if (estUnMessageAIgnorer(b)) return null;
  return _parseMtnPaiementMarchand(b) ??
      _parseMtnTransactionGenerique(b) ??
      _parseMtnRetrait(b) ??
      _parseMtnTransfertEnvoye(b) ??
      _parseMtnReception(b);
}

/// Point d'entrée unique du moteur de parsing : tente Orange Money puis
/// MTN Mobile Money. Retourne `null` si le SMS ne correspond à aucun
/// format reconnu (message à ignorer par défaut).
MoneyTransaction? parseSms(String body) {
  return parseOrangeMoney(body) ?? parseMtnMomo(body);
}
