import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models/transaction.dart';
import '../widgets/swipe_to_delete.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

/// Onglet listant les transactions des 30 derniers jours. Basé sur un
/// stream réactif : toute nouvelle transaction (saisie manuelle, SMS
/// détecté en direct ou rescan manuel) apparaît immédiatement, sans
/// action de rechargement de la part de l'utilisateur.
class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  final ScrollController _scrollController = ScrollController();
  // Transactions glissées hors de la liste : Dismissible exige qu'elles
  // disparaissent immédiatement, sans attendre la prochaine émission du
  // stream.
  final Set<String> _masquees = {};
  late final Stream<List<MoneyTransaction>> _transactions = AppDatabase.instance
      .watchTransactions(
          from: DateTime.now().subtract(const Duration(days: 30)));

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MoneyTransaction>>(
      stream: _transactions,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final transactions =
            snapshot.data!.where((t) => !_masquees.contains(t.id)).toList();
        if (transactions.isEmpty) {
          return const Center(
              child:
                  Text('Aucune transaction au cours des 30 derniers jours.'));
        }
        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return SwipeToDelete(
                transaction: tx,
                onDismissed: () {
                  setState(() => _masquees.add(tx.id));
                  supprimerAvecAnnulation(context, tx, onRestored: () {
                    if (mounted) setState(() => _masquees.remove(tx.id));
                  });
                },
                child: TransactionTile(
                  transaction: tx,
                  onLongPress: () {},
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TransactionDetailScreen(transaction: tx),
                  )),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
