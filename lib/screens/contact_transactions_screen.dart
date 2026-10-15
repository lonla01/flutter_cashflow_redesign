import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

/// Transactions échangées avec un contact, ouvertes depuis la liste
/// "Par contact / destinataire" du tableau de bord. Reçoit exactement les
/// transactions qui composent le total affiché là-bas (même mois, même
/// filtre de catégories), pour que les deux écrans concordent.
class ContactTransactionsScreen extends StatelessWidget {
  const ContactTransactionsScreen({
    super.key,
    required this.contact,
    required this.periode,
    required this.total,
    required this.transactions,
  });

  final String contact;

  /// Libellé de la période affichée (ex. "Octobre 2026").
  final String periode;

  /// Solde net avec ce contact, voir ContactTotal.total.
  final double total;
  final List<MoneyTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final triees = [...transactions]
      ..sort((a, b) => b.dateTransaction.compareTo(a.dateTransaction));
    final montant = NumberFormat('#,##0', 'fr_FR').format(total.abs());
    final couleur = total > 0
        ? Colors.green.shade700
        : total < 0
            ? Colors.red.shade700
            : null;

    return Scaffold(
      appBar: GradientAppBar(title: contact),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: triees.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              child: ListTile(
                title: Text(periode),
                subtitle: Text(
                    '${triees.length} transaction${triees.length > 1 ? 's' : ''} · solde net'),
                trailing: Text(
                  '${total > 0 ? '+' : total < 0 ? '-' : ''}$montant FCFA',
                  style: TextStyle(color: couleur, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            );
          }
          final tx = triees[index - 1];
          return TransactionTile(
            transaction: tx,
            onLongPress: () {},
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: tx),
            )),
          );
        },
      ),
    );
  }
}
