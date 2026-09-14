import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final MoneyTransaction transaction;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool modeSelection;
  final bool selectionnee;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
    required this.onLongPress,
    this.modeSelection = false,
    this.selectionnee = false,
  });

  @override
  Widget build(BuildContext context) {
    final estEntree = transaction.montantSigne > 0;
    final couleur = estEntree ? Colors.green.shade700 : Colors.red.shade700;
    final montantFmt = NumberFormat('#,##0', 'fr_FR').format(transaction.montant);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm').format(transaction.dateTransaction);

    return Card(
      color: selectionnee ? AppColors.navy700.withValues(alpha: 0.06) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selectionnee
            ? const BorderSide(color: AppColors.navy700, width: 1.4)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: modeSelection
            ? Checkbox(value: selectionnee, onChanged: (_) => onTap())
            : CircleAvatar(
                radius: 22,
                backgroundColor: couleur.withValues(alpha: 0.12),
                child: Icon(
                  estEntree ? Icons.arrow_downward : Icons.arrow_upward,
                  color: couleur,
                ),
              ),
        title: Text(
          transaction.contactNom ?? 'Contact inconnu',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${transaction.categorie} · $dateFmt',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${estEntree ? '+' : '-'}$montantFmt FCFA',
              style: TextStyle(color: couleur, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            if (transaction.statutEdition == EditStatus.editeManuellement)
              Text('modifié', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
