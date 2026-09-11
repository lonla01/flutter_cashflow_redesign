import 'package:supabase_flutter/supabase_flutter.dart';

/// Levée quand une erreur de synchronisation ne doit PAS être réessayée
/// (payload invalide, accès refusé...) : l'entrée passe directement en
/// statut `echec` plutôt que d'entrer dans la boucle de retry/backoff.
class NonRetryableSyncException implements Exception {
  final String message;
  NonRetryableSyncException(this.message);

  @override
  String toString() => 'NonRetryableSyncException: $message';
}

/// Abstraction sur le transport réseau de synchronisation, pour permettre
/// l'injection de faux transports dans les tests (échec systématique,
/// conflit simulé...) sans dépendre du client Supabase réel.
abstract class SyncTransport {
  /// Pousse un instantané JSON d'une transaction locale vers le serveur.
  /// Retourne la ligne canonique côté serveur après résolution de conflit
  /// (voir sync_upsert_transaction dans supabase/schema.sql) : peut être
  /// identique au payload envoyé (notre écriture a gagné) ou différente
  /// (une version plus récente existait déjà côté serveur).
  Future<Map<String, Object?>> pushTransaction(Map<String, Object?> payload);

  /// Récupère les lignes modifiées côté serveur depuis [since].
  Future<List<Map<String, Object?>>> pullChangedSince(DateTime since);
}

class SupabaseSyncTransport implements SyncTransport {
  SupabaseClient get _client => Supabase.instance.client;

  bool _estNonReessayable(PostgrestException e) {
    final code = e.code;
    if (code == null) return false;
    // Classes Postgres 22 (data exception) et 23 (integrity constraint
    // violation) : payload malformé, jamais résolu par un simple retry.
    // 42501 : accès refusé par une politique RLS.
    return code.startsWith('22') || code.startsWith('23') || code == '42501';
  }

  @override
  Future<Map<String, Object?>> pushTransaction(Map<String, Object?> payload) async {
    try {
      final result = await _client.rpc('sync_upsert_transaction', params: {'payload': payload});
      return Map<String, Object?>.from(result as Map);
    } on PostgrestException catch (e) {
      if (_estNonReessayable(e)) {
        throw NonRetryableSyncException(e.message);
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, Object?>>> pullChangedSince(DateTime since) async {
    final rows = await _client
        .from('transactions')
        .select()
        .gt('derniere_modification', since.toIso8601String())
        .order('derniere_modification');
    return (rows as List).map((r) => Map<String, Object?>.from(r as Map)).toList();
  }
}
