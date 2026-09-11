import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction sur l'état de connectivité réseau, pour permettre
/// l'injection d'un faux service dans les tests (mode avion simulé) sans
/// dépendre du plugin réel `connectivity_plus`.
abstract class ConnectivityChecker {
  /// Émet `true`/`false` à chaque changement de connectivité. Écouté en
  /// continu par [SyncService], pas seulement au lancement de l'app.
  Stream<bool> get onStatusChange;

  Future<bool> checkNow();
}

class ConnectivityPlusChecker implements ConnectivityChecker {
  final Connectivity _connectivity = Connectivity();

  bool _estEnLigne(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_estEnLigne);

  @override
  Future<bool> checkNow() async =>
      _estEnLigne(await _connectivity.checkConnectivity());
}
