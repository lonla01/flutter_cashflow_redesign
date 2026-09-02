import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../models/category_rule.dart';
import '../models/transaction.dart';
import '../services/categorization_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final MoneyTransaction transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TextEditingController _contactCtrl;
  late TextEditingController _notesCtrl;
  late String _categorie;
  bool _voirSmsBrut = false;

  @override
  void initState() {
    super.initState();
    _contactCtrl = TextEditingController(text: widget.transaction.contactNom ?? '');
    _notesCtrl = TextEditingController(text: widget.transaction.notes);
    _categorie = widget.transaction.categorie;
  }

  @override
  void dispose() {
    _contactCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final tx = widget.transaction;
    final categorieChangee = _categorie != tx.categorie;
    tx.contactNom = _contactCtrl.text.trim();
    tx.notes = _notesCtrl.text.trim();
    tx.categorie = _categorie;
    tx.statutEdition = EditStatus.editeManuellement;

    await AppDatabase.instance.updateTransaction(tx);
    if (categorieChangee) {
      await CategorizationService(AppDatabase.instance).learnFromCorrection(tx, _categorie);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction mise à jour.')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final montantFmt = NumberFormat('#,##0', 'fr_FR');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la transaction')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ligneInfo('Source', tx.source == TransactionSource.orangeMoney ? 'Orange Money' : 'MTN Mobile Money'),
          _ligneInfo('Type', tx.type.name),
          _ligneInfo('Montant', '${montantFmt.format(tx.montant)} FCFA'),
          _ligneInfo('Frais', '${montantFmt.format(tx.frais)} FCFA'),
          _ligneInfo('Date', dateFmt.format(tx.dateTransaction)),
          if (tx.soldeApres != null)
            _ligneInfo('Solde après transaction', '${montantFmt.format(tx.soldeApres!)} FCFA'),
          if (tx.idTransactionOperateur != null)
            _ligneInfo('Référence opérateur', tx.idTransactionOperateur!),
          const Divider(height: 32),

          TextField(
            controller: _contactCtrl,
            decoration: const InputDecoration(
              labelText: 'Contact / destinataire',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _categorie,
            decoration: const InputDecoration(
              labelText: 'Catégorie',
              border: OutlineInputBorder(),
            ),
            items: categoriesParDefaut
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _categorie = v ?? _categorie),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          if (tx.smsBrut != null) ...[
            TextButton.icon(
              onPressed: () => setState(() => _voirSmsBrut = !_voirSmsBrut),
              icon: Icon(_voirSmsBrut ? Icons.expand_less : Icons.expand_more),
              label: const Text('SMS original'),
            ),
            if (_voirSmsBrut)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tx.smsBrut!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            const SizedBox(height: 24),
          ],

          ElevatedButton.icon(
            onPressed: _enregistrer,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _ligneInfo(String label, String valeur) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(valeur, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
