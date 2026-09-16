import 'package:flutter/material.dart';

import '../services/ai_model.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';

/// Réglages > Modèle IA : choix du modèle utilisé pour l'extraction de
/// reçu (voir ReceiptExtractionService). Réglage local à l'appareil,
/// pensé pour comparer plusieurs fournisseurs en coût/performance sur
/// cette tâche précise — chaque essai est aussi journalisé côté serveur
/// (receipt_scan_logs) pour une comparaison a posteriori.
class AiModelScreen extends StatefulWidget {
  const AiModelScreen({super.key});

  @override
  State<AiModelScreen> createState() => _AiModelScreenState();
}

class _AiModelScreenState extends State<AiModelScreen> {
  String? _selection;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final id = await AiModelPreference.getSelectedModelId();
    if (mounted) setState(() => _selection = id);
  }

  Future<void> _choisir(String id) async {
    setState(() => _selection = id);
    await AiModelPreference.setSelectedModelId(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Modèle IA'),
      body: _selection == null
          ? const Center(child: CircularProgressIndicator())
          : RadioGroup<String>(
              groupValue: _selection,
              onChanged: (v) => _choisir(v!),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: availableAiModels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final model = availableAiModels[index];
                  final selectionne = model.id == _selection;
                  return Card(
                    color: selectionne ? AppColors.navy700.withValues(alpha: 0.06) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: selectionne
                          ? const BorderSide(color: AppColors.navy700, width: 1.4)
                          : BorderSide.none,
                    ),
                    child: RadioListTile<String>(
                      value: model.id,
                      title: Text(model.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(model.note),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
