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

/// Types d'entités synchronisées, avec leur table et leur RPC Supabase
/// (voir supabase/schema.sql). [keyColumn] départage les lignes de même
/// synced_at dans le curseur de pull.
enum SyncEntity {
  transaction('transaction', 'transactions', 'sync_upsert_transaction', 'id'),
  category('category', 'categories', 'sync_upsert_category', 'cle'),
  categoryRule('category_rule', 'category_rules', 'sync_upsert_category_rule', 'cle');

  const SyncEntity(this.key, this.table, this.rpc, this.keyColumn);

  /// Valeur stockée dans `sync_queue.entity_type` et `sync_cursors`.
  final String key;
  final String table;
  final String rpc;
  final String keyColumn;

  static SyncEntity fromKey(String key) => values.firstWhere((e) => e.key == key);
}

/// Position du pull dans une table serveur : on reprend après la ligne
/// (syncedAt, cle). [syncedAt] est un horodatage UTC ISO 8601.
class SyncCursor {
  const SyncCursor(this.syncedAt, this.cle);
  final String syncedAt;
  final String cle;
}

/// Abstraction sur le transport réseau de synchronisation, pour permettre
/// l'injection de faux transports dans les tests (échec systématique,
/// conflit simulé...) sans dépendre du client Supabase réel.
abstract class SyncTransport {
  /// Nombre maximal de lignes renvoyées par [pullPage].
  static const pageSize = 500;

  /// Pousse un instantané JSON d'une entité locale vers le serveur.
  /// Retourne la ligne canonique côté serveur après résolution de conflit
  /// last-write-wins (voir les RPC sync_upsert_* dans
  /// supabase/schema.sql) : identique au payload envoyé si notre écriture
  /// a gagné, différente si une version plus récente existait déjà.
  Future<Map<String, Object?>> push(SyncEntity entity, Map<String, Object?> payload);

  /// Lignes écrites côté serveur après [after] (toutes si null), triées
  /// par (synced_at, clé), au plus [pageSize].
  Future<List<Map<String, Object?>>> pullPage(SyncEntity entity, SyncCursor? after);
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
  Future<Map<String, Object?>> push(SyncEntity entity, Map<String, Object?> payload) async {
    try {
      final result = await _client.rpc(entity.rpc, params: {'payload': payload});
      return Map<String, Object?>.from(result as Map);
    } on PostgrestException catch (e) {
      if (_estNonReessayable(e)) {
        throw NonRetryableSyncException(e.message);
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, Object?>>> pullPage(SyncEntity entity, SyncCursor? after) async {
    var query = _client.from(entity.table).select();
    if (after != null) {
      // Pagination par curseur (synced_at, clé) : synced_at seul ne suffit
      // pas, des lignes écrites dans une même transaction SQL partagent la
      // même valeur. Valeurs entre guillemets pour la syntaxe or() de
      // PostgREST.
      final ts = '"${after.syncedAt}"';
      final cle = '"${after.cle.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
      query = query.or(
        'synced_at.gt.$ts,and(synced_at.eq.$ts,${entity.keyColumn}.gt.$cle)',
      );
    }
    final rows = await query
        .order('synced_at', ascending: true)
        .order(entity.keyColumn, ascending: true)
        .limit(SyncTransport.pageSize);
    return (rows as List).map((r) => Map<String, Object?>.from(r as Map)).toList();
  }
}
