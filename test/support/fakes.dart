import 'dart:async';

import 'package:mobile_money_tracker/services/auth_gate.dart';
import 'package:mobile_money_tracker/services/connectivity_service.dart';
import 'package:mobile_money_tracker/services/sync_transport.dart';

/// Faux [AuthGate] pour les tests : pas de réseau, pas de client Supabase.
class FakeAuthGate implements AuthGate {
  FakeAuthGate({bool authenticated = true, this.confirmEmailOnSignUp = false})
      : _authenticated = authenticated;

  bool _authenticated;
  final _controller = StreamController<bool>.broadcast();
  Object? errorOnSignIn;

  /// Si `true`, simule un projet Supabase avec confirmation d'email requise :
  /// `signUp` n'ouvre pas de session tant que le lien reçu par email n'a pas
  /// été suivi.
  bool confirmEmailOnSignUp;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Stream<bool> get onAuthChanged => _controller.stream;

  void setAuthenticated(bool value) {
    _authenticated = value;
    _controller.add(value);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (errorOnSignIn != null) throw errorOnSignIn!;
    setAuthenticated(true);
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    if (errorOnSignIn != null) throw errorOnSignIn!;
    if (confirmEmailOnSignUp) return false;
    setAuthenticated(true);
    return true;
  }

  @override
  Future<void> signOut() async => setAuthenticated(false);

  void dispose() => _controller.close();
}

/// Faux [ConnectivityChecker] : connectivité pilotée manuellement par le
/// test, pour simuler le mode avion sans dépendre du plugin réel.
class FakeConnectivityChecker implements ConnectivityChecker {
  FakeConnectivityChecker({bool online = true}) : _online = online;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get onStatusChange => _controller.stream;

  @override
  Future<bool> checkNow() async => _online;

  void setOnline(bool value) {
    _online = value;
    _controller.add(value);
  }

  void dispose() => _controller.close();
}

/// Transport qui échoue systématiquement (panne réseau / mode avion) : les
/// entrées doivent rester `en_attente`, jamais provoquer d'exception non
/// interceptée.
class AlwaysFailingSyncTransport implements SyncTransport {
  @override
  Future<Map<String, Object?>> pushTransaction(Map<String, Object?> payload) {
    throw Exception('réseau injoignable (faux transport de test)');
  }

  @override
  Future<List<Map<String, Object?>>> pullChangedSince(DateTime since) {
    throw Exception('réseau injoignable (faux transport de test)');
  }
}

/// Renvoie le payload envoyé tel quel : l'écriture locale "gagne" toujours
/// le conflit last-write-wins (dates identiques).
class EchoingSyncTransport implements SyncTransport {
  @override
  Future<Map<String, Object?>> pushTransaction(Map<String, Object?> payload) async =>
      Map<String, Object?>.from(payload);

  @override
  Future<List<Map<String, Object?>>> pullChangedSince(DateTime since) async => [];
}

/// Simule un conflit : renvoie toujours une ligne serveur dont
/// `derniere_modification` est postérieure à celle envoyée (le serveur a
/// gagné le conflit last-write-wins).
class ConflictingSyncTransport implements SyncTransport {
  ConflictingSyncTransport({required this.serverRowBuilder});

  final Map<String, Object?> Function(Map<String, Object?> localPayload) serverRowBuilder;

  @override
  Future<Map<String, Object?>> pushTransaction(Map<String, Object?> payload) async =>
      serverRowBuilder(payload);

  @override
  Future<List<Map<String, Object?>>> pullChangedSince(DateTime since) async => [];
}

/// Simule une erreur non réessayable (payload invalide, accès refusé).
class NonRetryableThrowingTransport implements SyncTransport {
  @override
  Future<Map<String, Object?>> pushTransaction(Map<String, Object?> payload) {
    throw NonRetryableSyncException('payload invalide (faux transport de test)');
  }

  @override
  Future<List<Map<String, Object?>>> pullChangedSince(DateTime since) async => [];
}
