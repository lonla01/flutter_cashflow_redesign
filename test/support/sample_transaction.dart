import 'package:mobile_money_tracker/models/transaction.dart';

MoneyTransaction buildTransaction({
  String? id,
  double montant = 5000,
  String categorie = 'Alimentation',
  String? contactNom = 'Boutique Test',
  DateTime? dateTransaction,
  String? idTransactionOperateur,
}) {
  return MoneyTransaction(
    id: id,
    source: TransactionSource.orangeMoney,
    type: TransactionType.paiementMarchand,
    montant: montant,
    contactNom: contactNom,
    categorie: categorie,
    dateTransaction: dateTransaction ?? DateTime.now(),
    idTransactionOperateur: idTransactionOperateur,
  );
}
