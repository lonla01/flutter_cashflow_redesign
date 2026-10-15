import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../services/export_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

enum _Format { csv, pdf }

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

  /// Exporte exactement la liste affichée (même période, même filtre de
  /// catégories que le tableau de bord), puis ouvre le partage.
  Future<void> _exporter(BuildContext context, _Format format, List<MoneyTransaction> liste) async {
    final messenger = ScaffoldMessenger.of(context);
    final nom = ExportService.nomDeFichier('transactions_${contact}_$periode');
    try {
      final fichier = format == _Format.csv
          ? await ExportService.exporterCsv(liste, nom)
          : await ExportService.exporterPdf(liste, 'Transactions avec $contact - $periode', nom);
      await ExportService.partager(fichier);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Export impossible : $e")));
    }
  }

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
      appBar: GradientAppBar(
        title: contact,
        actions: [
          PopupMenuButton<_Format>(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exporter',
            enabled: triees.isNotEmpty,
            onSelected: (format) => _exporter(context, format, triees),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _Format.csv,
                child: ListTile(leading: Icon(Icons.table_chart), title: Text('Exporter en CSV')),
              ),
              PopupMenuItem(
                value: _Format.pdf,
                child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('Exporter en PDF')),
              ),
            ],
          ),
        ],
      ),
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
