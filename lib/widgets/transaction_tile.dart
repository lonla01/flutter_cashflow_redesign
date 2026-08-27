import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  final MoneyTransaction transaction;
  final VoidCallback onTap;

  const TransactionTile({super.key, required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final estEntree = transaction.montantSigne > 0;
    final couleur = estEntree ? Colors.green.shade700 : Colors.red.shade700;
    final montantFmt = NumberFormat('#,##0', 'fr_FR').format(transaction.montant);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm').format(transaction.dateTransaction);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: couleur.withValues(alpha: 0.15),
        child: Icon(
          estEntree ? Icons.arrow_downward : Icons.arrow_upward,
          color: couleur,
        ),
      ),
      title: Text(transaction.contactNom ?? 'Contact inconnu'),
      subtitle: Text('${transaction.categorie} · $dateFmt'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${estEntree ? '+' : '-'}$montantFmt FCFA',
            style: TextStyle(color: couleur, fontWeight: FontWeight.bold),
          ),
          if (transaction.statutEdition == EditStatus.editeManuellement)
            const Text('modifié', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
