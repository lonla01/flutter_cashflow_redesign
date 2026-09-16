import 'package:shared_preferences/shared_preferences.dart';

/// Un modèle IA sélectionnable pour l'extraction de reçu. [id] est envoyé
/// tel quel à la fonction Edge `extract-receipt`
/// (voir supabase/functions/extract-receipt/index.ts), qui le découpe en
/// "<fournisseur>:<modèle>" pour router vers le bon appel API.
class AiModel {
  const AiModel({required this.id, required this.label, required this.note});

  final String id;
  final String label;
  final String note;
}

/// Pool de modèles proposé dans Réglages > Modèle IA, choisi pour couvrir
/// plusieurs fournisseurs à comparer en coût/performance sur cette tâche
/// précise (extraction de champs depuis une photo de reçu).
const List<AiModel> availableAiModels = [
  AiModel(
    id: 'anthropic:claude-sonnet-5',
    label: 'Claude Sonnet 5',
    note: 'Anthropic — équilibré',
  ),
  AiModel(
    id: 'openai:gpt-5',
    label: 'GPT-5',
    note: 'OpenAI — haut de gamme',
  ),
  AiModel(
    id: 'openai:gpt-5-mini',
    label: 'GPT-5 mini',
    note: 'OpenAI — rapide et économique',
  ),
  AiModel(
    id: 'openrouter:qwen/qwen2.5-vl-72b-instruct',
    label: 'Qwen2.5-VL 72B',
    note: 'Qwen via OpenRouter — spécialisé OCR/documents',
  ),
  AiModel(
    id: 'openrouter:qwen/qwen3-vl-30b-a3b-instruct',
    label: 'Qwen3-VL 30B',
    note: 'Qwen via OpenRouter — spécialisé OCR/documents',
  ),
  AiModel(
    id: 'google:gemini-2.5-flash',
    label: 'Gemini 2.5 Flash',
    note: 'Google — rapide et économique',
  ),
];

const String defaultAiModelId = 'anthropic:claude-sonnet-5';

/// Préférence locale (par appareil) du modèle IA choisi pour l'extraction
/// de reçu. Volontairement locale plutôt que synchronisée : c'est un
/// réglage de test/debug, pas une donnée métier.
class AiModelPreference {
  static const _prefsKey = 'selected_ai_model_id';

  static Future<String> getSelectedModelId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && availableAiModels.any((m) => m.id == saved)) {
      return saved;
    }
    return defaultAiModelId;
  }

  static Future<void> setSelectedModelId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
  }

  static AiModel modelFor(String id) => availableAiModels.firstWhere(
        (m) => m.id == id,
        orElse: () => availableAiModels.first,
      );
}
