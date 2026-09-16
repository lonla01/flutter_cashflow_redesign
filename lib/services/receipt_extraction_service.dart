import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'ai_model.dart';

/// Champs extraits d'une photo de reçu par la fonction Edge
/// `extract-receipt`. Chaque champ peut être `null` si l'IA n'a pas su le
/// lire — l'appelant doit toujours laisser l'utilisateur compléter/corriger
/// avant d'enregistrer, jamais faire confiance aveuglément à l'extraction.
class ReceiptExtractedFields {
  final double? montant;
  final String? marchand;
  final DateTime? date;
  final String? notes;

  ReceiptExtractedFields({this.montant, this.marchand, this.date, this.notes});

  factory ReceiptExtractedFields.fromMap(Map<String, Object?> map) {
    final montantRaw = map['montant'];
    final dateRaw = map['date'];
    return ReceiptExtractedFields(
      montant: montantRaw == null ? null : (montantRaw as num).toDouble(),
      marchand: map['marchand'] as String?,
      date: dateRaw is String ? DateTime.tryParse(dateRaw) : null,
      notes: map['notes'] as String?,
    );
  }

  bool get estVide =>
      montant == null && marchand == null && date == null && notes == null;
}

class ReceiptExtractionException implements Exception {
  final String message;
  ReceiptExtractionException(this.message);

  @override
  String toString() => message;
}

/// Envoie une photo de reçu à la fonction Edge Supabase `extract-receipt`
/// (voir supabase/functions/extract-receipt/index.ts) pour en extraire les
/// champs d'une transaction. La clé de l'API IA reste côté serveur : ce
/// service ne fait que transmettre l'image et relayer le résultat.
class ReceiptExtractionService {
  Future<ReceiptExtractedFields> extraire({
    required List<int> imageBytes,
    required String mimeType,
    String? modelId,
  }) async {
    final FunctionResponse response;
    try {
      response = await Supabase.instance.client.functions.invoke(
        'extract-receipt',
        body: {
          'image_base64': base64Encode(imageBytes),
          'mime_type': mimeType,
          'model_id': modelId ?? defaultAiModelId,
        },
      );
    } on FunctionException catch (e) {
      throw ReceiptExtractionException(
        e.details?.toString() ?? "Échec de l'extraction (${e.status}).",
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw ReceiptExtractionException(
          "Réponse inattendue du service d'extraction.");
    }
    final map = Map<String, Object?>.from(data);
    if (map['error'] != null) {
      throw ReceiptExtractionException(map['error'].toString());
    }
    return ReceiptExtractedFields.fromMap(map);
  }
}
