import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models/transaction.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

/// Onglet listant les transactions des 30 derniers jours.
class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> {
  List<MoneyTransaction> _transactions = [];
  bool _chargement = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final depuis = DateTime.now().subtract(const Duration(days: 30));
    final transactions = await AppDatabase.instance.getAllTransactions(from: depuis);
    setState(() {
      _transactions = transactions;
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_transactions.isEmpty) {
      return const Center(
          child: Text('Aucune transaction au cours des 30 derniers jours.'));
    }
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: RefreshIndicator(
        onRefresh: _charger,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          itemCount: _transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tx = _transactions[index];
            return TransactionTile(
              transaction: tx,
              onLongPress: () {},
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TransactionDetailScreen(transaction: tx),
                ));
                _charger();
              },
            );
          },
        ),
      ),
    );
  }
}
