/// Configuration du client Supabase. La clé "publishable"/anon est conçue
/// par Supabase pour être embarquée côté client (elle apparaît dans chaque
/// requête réseau de toute façon) : la vraie barrière de sécurité est le
/// Row Level Security sur les tables Postgres, pas le secret de cette clé.
///
/// `--dart-define=SUPABASE_URL=...` / `--dart-define=SUPABASE_ANON_KEY=...`
/// permettent de surcharger ces valeurs pour un futur environnement
/// distinct (staging/prod) sans modifier le code.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wrtxmzncaxnvtcmswbyn.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_SBQ4hi4-zWuMzXxxH3l4bw_gre6Ndv3',
  );
}
