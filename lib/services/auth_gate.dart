import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Abstraction sur l'authentification, pour permettre l'injection d'un faux
/// service dans les tests sans dépendre du client Supabase réel.
///
/// `isAuthenticated` doit toujours pouvoir être lu de façon synchrone et
/// sans appel réseau : Supabase restaure la session depuis le stockage
/// local pendant `Supabase.initialize()`, donc "suis-je connecté ?" ne
/// dépend jamais de la connectivité (voir lib/main.dart, _RacineApp).
abstract class AuthGate {
  /// Instance active, mutable pour permettre son remplacement dans les
  /// tests.
  static AuthGate current = SupabaseAuthGate();

  bool get isAuthenticated;

  Stream<bool> get onAuthChanged;

  Future<void> signIn({required String email, required String password});

  /// Retourne `true` si l'inscription a immédiatement ouvert une session
  /// (confirmation d'email désactivée côté Supabase), `false` si un email de
  /// confirmation vient d'être envoyé et que la session ne sera créée
  /// qu'après que l'utilisateur ait cliqué sur le lien qu'il contient.
  Future<bool> signUp({required String email, required String password});

  Future<void> signOut();

  /// Envoie un email contenant un lien de réinitialisation de mot de passe.
  /// Le lien ouvre l'app sur `SupabaseConfig.authRedirectUrl` avec un token
  /// de récupération, ce qui déclenche un événement sur
  /// [onPasswordRecovery].
  Future<void> resetPasswordForEmail(String email);

  /// Définit un nouveau mot de passe. Ne fonctionne que pendant une session
  /// valide — en pratique, juste après [onPasswordRecovery], tant que la
  /// session de récupération établie par le lien est active.
  Future<void> updatePassword(String newPassword);

  /// Émet à chaque fois que l'utilisateur ouvre l'app via un lien de
  /// réinitialisation de mot de passe (voir _RacineAppState dans main.dart,
  /// qui écoute ce stream pour présenter ResetPasswordScreen).
  Stream<void> get onPasswordRecovery;
}

class SupabaseAuthGate implements AuthGate {
  /// [auth] est injectable pour les tests (ex. un `GoTrueClient` simulé avec
  /// mocktail) ; par défaut, utilise le client Supabase réel initialisé dans
  /// main.dart.
  SupabaseAuthGate({GoTrueClient? auth}) : _auth = auth ?? Supabase.instance.client.auth;

  final GoTrueClient _auth;

  @override
  bool get isAuthenticated => _auth.currentSession != null;

  @override
  Stream<bool> get onAuthChanged =>
      _auth.onAuthStateChange.map((state) => state.session != null);

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: SupabaseConfig.authRedirectUrl,
    );
    return response.session != null;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> resetPasswordForEmail(String email) => _auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.authRedirectUrl,
      );

  @override
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Stream<void> get onPasswordRecovery => _auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.passwordRecovery)
      .map((_) {});
}
