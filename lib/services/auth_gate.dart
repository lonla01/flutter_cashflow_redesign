import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> signUp({required String email, required String password});

  Future<void> signOut();
}

class SupabaseAuthGate implements AuthGate {
  GoTrueClient get _auth => Supabase.instance.client.auth;

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
  Future<void> signUp({required String email, required String password}) async {
    await _auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
