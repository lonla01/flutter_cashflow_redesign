import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../models/transaction.dart';
import '../services/ai_model.dart';
import '../services/categorization_service.dart';
import '../services/receipt_extraction_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/gradient_button.dart';

/// Saisie d'une transaction qui n'est pas passée par le parsing SMS : soit
/// entièrement à la main, soit pré-remplie à partir d'une photo de reçu
/// analysée par IA (voir ReceiptExtractionService). Dans les deux cas,
/// l'utilisateur revoit/corrige les champs avant d'enregistrer — l'IA ne
/// crée jamais une transaction directement.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  final _fraisCtrl = TextEditingController(text: '0');
  final _contactNomCtrl = TextEditingController();
  final _contactNumeroCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  TransactionType _type = TransactionType.paiementMarchand;
  String? _categorie;
  DateTime _date = DateTime.now();
  bool _extractionEnCours = false;
  bool _enregistrementEnCours = false;

  @override
  void dispose() {
    _montantCtrl.dispose();
    _fraisCtrl.dispose();
    _contactNomCtrl.dispose();
    _contactNumeroCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _scannerRecu() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 70, maxWidth: 1600);
    if (picked == null || !mounted) return;

    setState(() => _extractionEnCours = true);
    final chrono = Stopwatch()..start();
    try {
      final bytes = await picked.readAsBytes();
      final mimeType = picked.mimeType ?? 'image/jpeg';
      final modelId = await AiModelPreference.getSelectedModelId();
      final modele = AiModelPreference.modelFor(modelId);
      final champs = await ReceiptExtractionService()
          .extraire(imageBytes: bytes, mimeType: mimeType, modelId: modelId);
      chrono.stop();

      if (champs.estVide) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Aucune information lisible sur cette photo (${modele.label}, '
                '${chrono.elapsedMilliseconds} ms). Complétez manuellement.',
              ),
            ),
          );
        }
        return;
      }

      if (champs.montant != null) {
        _montantCtrl.text = _formatMontantPourChamp(champs.montant!);
      }
      if (champs.marchand != null && champs.marchand!.isNotEmpty) {
        _contactNomCtrl.text = champs.marchand!;
      }
      if (champs.notes != null && champs.notes!.isNotEmpty) {
        _notesCtrl.text = champs.notes!;
      }

      var nouvelleDate = _date;
      if (champs.date != null) {
        nouvelleDate =
            DateTime(champs.date!.year, champs.date!.month, champs.date!.day);
      }

      // Réutilise les règles de catégorisation existantes (mêmes que pour
      // les transactions parsées depuis un SMS) plutôt que de faire
      // deviner une catégorie à l'IA, qui n'a aucune visibilité sur les
      // catégories propres à cet utilisateur.
      String? categorieSuggeree;
      if (champs.marchand != null && champs.marchand!.isNotEmpty) {
        categorieSuggeree =
            await CategorizationService(AppDatabase.instance).suggestCategory(
          MoneyTransaction(
            source: TransactionSource.manuel,
            type: _type,
            montant: champs.montant ?? 0,
            contactNom: champs.marchand,
            dateTransaction: nouvelleDate,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _date = nouvelleDate;
        if (categorieSuggeree != null) _categorie = categorieSuggeree;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Champs pré-remplis via ${modele.label} (${chrono.elapsedMilliseconds} ms) '
            "— vérifiez avant d'enregistrer.",
          ),
        ),
      );
    } on ReceiptExtractionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _extractionEnCours = false);
    }
  }

  String _formatMontantPourChamp(double montant) =>
      montant == montant.roundToDouble()
          ? montant.toStringAsFixed(0)
          : montant.toString();

  Future<void> _choisirDate() async {
    final choisie = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (choisie != null) {
      setState(() => _date = DateTime(
          choisie.year, choisie.month, choisie.day, _date.hour, _date.minute));
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enregistrementEnCours = true);
    try {
      final montant = double.parse(_montantCtrl.text.replaceAll(',', '.'));
      final frais = double.tryParse(_fraisCtrl.text.replaceAll(',', '.')) ?? 0;
      final tx = MoneyTransaction(
        source: TransactionSource.manuel,
        type: _type,
        montant: montant,
        frais: frais,
        contactNom: _contactNomCtrl.text.trim().isEmpty
            ? null
            : _contactNomCtrl.text.trim(),
        contactNumero: _contactNumeroCtrl.text.trim().isEmpty
            ? null
            : _contactNumeroCtrl.text.trim(),
        categorie: _categorie ?? 'Autre',
        dateTransaction: _date,
        notes: _notesCtrl.text.trim(),
        statutEdition: EditStatus.editeManuellement,
      );
      await AppDatabase.instance.insertTransactionIfNew(tx);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _enregistrementEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: const GradientAppBar(title: 'Nouvelle transaction'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _extractionEnCours ? null : _scannerRecu,
                icon: _extractionEnCours
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.document_scanner_outlined),
                label: Text(_extractionEnCours
                    ? 'Analyse en cours...'
                    : 'Scanner un reçu'),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<TransactionType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: TransactionType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(_libelleType(t))))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _montantCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _fraisCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Frais (FCFA)'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contactNomCtrl,
              decoration:
                  const InputDecoration(labelText: 'Contact / marchand'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contactNumeroCtrl,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(labelText: 'Numéro (optionnel)'),
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<String>>(
              stream: AppDatabase.instance.watchCategories(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? const [];
                final valeur = (_categorie != null &&
                        categories.contains(_categorie))
                    ? _categorie
                    : (categories.contains('Autre')
                        ? 'Autre'
                        : (categories.isNotEmpty ? categories.first : null));
                // La clé force la recréation du champ quand la valeur change
                // pour une raison externe (suggestion de l'IA) : `initialValue`
                // d'un FormField n'est pris en compte qu'à la création.
                return DropdownButtonFormField<String>(
                  key: ValueKey(valeur),
                  initialValue: valeur,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _categorie = v),
                );
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _choisirDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: Text(dateFmt.format(_date)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 24),
            GradientButton(
              onPressed: _enregistrementEnCours ? null : _enregistrer,
              loading: _enregistrementEnCours,
              icon: Icons.save,
              label: 'Enregistrer',
            ),
          ],
        ),
      ),
    );
  }

  String _libelleType(TransactionType t) => switch (t) {
        TransactionType.transfertEnvoye => 'Transfert envoyé',
        TransactionType.depotRecu => 'Dépôt reçu',
        TransactionType.retrait => 'Retrait',
        TransactionType.paiementMarchand => 'Paiement marchand',
        TransactionType.reception => 'Réception',
        TransactionType.paiementService => 'Paiement de service',
      };
}
