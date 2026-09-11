// Test de démarrage de l'app : vérifie le routage racine (authentification
// puis onboarding/écran principal) sans dépendre du réseau ni d'un vrai
// client Supabase, grâce aux seams AppDatabase.instance / AuthGate.current.

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_money_tracker/db/app_database.dart';
import 'package:mobile_money_tracker/main.dart';
import 'package:mobile_money_tracker/screens/auth_screen.dart';
import 'package:mobile_money_tracker/services/auth_gate.dart';
import 'package:mobile_money_tracker/services/sync_service.dart';

import 'support/fakes.dart';

void main() {
  final defaultSyncServiceBuilder = SyncServiceFactory.builder;

  setUp(() {
    AppDatabase.instance = AppDatabase.withExecutor(NativeDatabase.memory());
    SyncServiceFactory.builder = (db) => SyncService(
          db: db,
          connectivity: FakeConnectivityChecker(online: false),
          transport: AlwaysFailingSyncTransport(),
        );
  });

  tearDown(() async {
    await AppDatabase.instance.close();
    SyncServiceFactory.builder = defaultSyncServiceBuilder;
  });

  testWidgets('Utilisateur non authentifié -> écran de connexion', (tester) async {
    AuthGate.current = FakeAuthGate(authenticated: false);

    await tester.pumpWidget(const MobileMoneyTrackerApp());
    await tester.pump();

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Utilisateur authentifié, base locale vide -> onboarding', (tester) async {
    AuthGate.current = FakeAuthGate(authenticated: true);

    await tester.pumpWidget(const MobileMoneyTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Découvrir avec des données de démo'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Démonte explicitement l'arbre ici : SyncService.stop() annule un
    // stream Drift (watchPendingSyncEntries) dont le nettoyage interne
    // programme un Timer.zero. Si le démontage n'a lieu qu'après la fin du
    // test (comportement par défaut de flutter_test, qui le fait au tout
    // début du test suivant), ce timer reste "en attente" au moment où le
    // framework vérifie qu'aucun timer ne subsiste : le test échoue et,
    // pire, le test runner reste bloqué plus d'une minute en essayant de
    // s'arrêter proprement.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
