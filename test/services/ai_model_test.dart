import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_tracker/services/ai_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('availableAiModels', () {
    test('contient les six modèles attendus, tous avec un id unique', () {
      expect(availableAiModels, hasLength(6));
      final ids = availableAiModels.map((m) => m.id).toSet();
      expect(ids, hasLength(6));
    });

    test('defaultAiModelId correspond à un modèle du pool', () {
      expect(availableAiModels.any((m) => m.id == defaultAiModelId), isTrue);
    });
  });

  group('AiModelPreference', () {
    test('renvoie le modèle par défaut quand rien n\'est enregistré', () async {
      expect(await AiModelPreference.getSelectedModelId(), defaultAiModelId);
    });

    test('mémorise et relit le modèle choisi', () async {
      const choisi = 'openai:gpt-5-mini';
      await AiModelPreference.setSelectedModelId(choisi);
      expect(await AiModelPreference.getSelectedModelId(), choisi);
    });

    test('retombe sur le défaut si la valeur enregistrée ne correspond plus à un modèle connu', () async {
      SharedPreferences.setMockInitialValues({'selected_ai_model_id': 'defunct:old-model'});
      expect(await AiModelPreference.getSelectedModelId(), defaultAiModelId);
    });

    test('modelFor retrouve le bon modèle par id', () {
      final model = AiModelPreference.modelFor('google:gemini-2.5-flash');
      expect(model.label, 'Gemini 2.5 Flash');
    });

    test('modelFor retombe sur le premier modèle pour un id inconnu', () {
      final model = AiModelPreference.modelFor('inconnu:x');
      expect(model, availableAiModels.first);
    });
  });
}
