import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../models/transaction.dart';
import '../services/categorization_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/gradient_button.dart';

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
    var nbSimilaires = 0;
    if (categorieChangee) {
      await CategorizationService(AppDatabase.instance).learnFromCorrection(tx, _categorie);
      nbSimilaires = await AppDatabase.instance.reassignSimilarTransactions(tx, _categorie);
    }
    if (mounted) {
      final message = nbSimilaires > 0
          ? 'Transaction mise à jour. $nbSimilaires transaction${nbSimilaires > 1 ? 's' : ''} similaire${nbSimilaires > 1 ? 's' : ''} recatégorisée${nbSimilaires > 1 ? 's' : ''}.'
          : 'Transaction mise à jour.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final estEntree = tx.montantSigne > 0;
    final couleurMontant = estEntree ? Colors.green.shade700 : Colors.red.shade700;
    final montantFmt = NumberFormat('#,##0', 'fr_FR');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: const GradientAppBar(title: 'Détail de la transaction'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _ligneInfo('Source', tx.source == TransactionSource.orangeMoney ? 'Orange Money' : 'MTN Mobile Money'),
                  _ligneInfo('Type', tx.type.name),
                  _ligneInfo(
                    'Montant',
                    '${estEntree ? '+' : '-'}${montantFmt.format(tx.montant)} FCFA',
                    valeurCouleur: couleurMontant,
                  ),
                  _ligneInfo('Frais', '${montantFmt.format(tx.frais)} FCFA'),
                  _ligneInfo('Date', dateFmt.format(tx.dateTransaction)),
                  if (tx.soldeApres != null)
                    _ligneInfo('Solde après transaction', '${montantFmt.format(tx.soldeApres!)} FCFA'),
                  if (tx.idTransactionOperateur != null)
                    _ligneInfo('Référence opérateur', tx.idTransactionOperateur!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _contactCtrl,
            decoration: const InputDecoration(labelText: 'Contact / destinataire'),
          ),
          const SizedBox(height: 16),

          StreamBuilder<List<String>>(
            stream: AppDatabase.instance.watchCategories(),
            builder: (context, snapshot) {
              // La catégorie actuelle de la transaction peut avoir été
              // retirée entre-temps de l'écran Réglages > Catégories : on
              // l'inclut toujours dans les choix, sinon DropdownButtonFormField
              // lève une erreur (valeur sélectionnée absente des items).
              final categories = {_categorie, ...?snapshot.data}.toList()..sort();
              return DropdownButtonFormField<String>(
                initialValue: _categorie,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _categorie = v ?? _categorie),
              );
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(tx.smsBrut!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            const SizedBox(height: 24),
          ],

          GradientButton(
            onPressed: _enregistrer,
            icon: Icons.save,
            label: 'Enregistrer',
          ),
        ],
      ),
    );
  }

  Widget _ligneInfo(String label, String valeur, {Color? valeurCouleur}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
            Text(
              valeur,
              style: TextStyle(fontWeight: FontWeight.w700, color: valeurCouleur),
            ),
          ],
        ),
      );
}
