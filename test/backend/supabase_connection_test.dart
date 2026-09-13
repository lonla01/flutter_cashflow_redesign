import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'package:mobile_money_tracker/config/supabase_config.dart';

/// Vérifie que le backend Supabase réellement déployé (pas un mock)
/// expose le schéma attendu par l'app — en particulier la fonction RPC
/// `sync_upsert_transaction` (voir supabase/schema.sql), qui est le
/// script SQL à exécuter manuellement dans l'éditeur SQL du projet et
/// n'est jamais appliqué automatiquement par le build.
///
/// Ce test aurait immédiatement détecté l'incident du 2026-09-13 : le
/// schéma n'avait jamais été appliqué au projet Supabase réel, alors que
/// tous les tests unitaires (mockés, voir sync_service_test.dart) et
/// `flutter analyze` restaient verts. Sans lui, la seule façon de le
/// remarquer était l'écran "Connexion" restant bloqué sur un appareil
/// réel.
///
/// Nécessite un accès réseau au vrai projet configuré dans
/// [SupabaseConfig] : exclu de `flutter test` par défaut (voir
/// dart_test.yaml). À lancer explicitement, par ex. avant une release ou
/// après une migration SQL :
///   flutter test --tags live --run-skipped
void main() {
  test(
    'la fonction RPC sync_upsert_transaction existe côté serveur',
    () async {
      final client = SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey);

      // Payload délibérément invalide (id manquant) : si la fonction
      // existe, Postgres refuse l'insertion (contrainte NOT NULL sur id,
      // code 23502) sans rien écrire. Si la fonction/le schéma n'existe
      // pas, PostgREST répond PGRST202 "function not found" — exactement
      // la panne qu'on veut détecter ici, sans avoir besoin d'un vrai
      // utilisateur authentifié.
      try {
        await client.rpc('sync_upsert_transaction', params: {'payload': <String, Object?>{}});
        fail(
          'sync_upsert_transaction a accepté un payload sans id : '
          'la validation côté serveur a changé, ce test doit être revu.',
        );
      } on PostgrestException catch (e) {
        expect(
          e.code,
          '23502',
          reason: 'Code inattendu (${e.code}: ${e.message}). '
              "PGRST202 signifie que le schéma Supabase (supabase/schema.sql) "
              "n'est pas appliqué sur ce projet — voir l'éditeur SQL du "
              'dashboard Supabase.',
        );
      }
    },
    tags: ['live'],
  );
}
