// Test de démarrage de l'app : vérifie le routage racine (authentification
// puis onboarding/écran principal) sans dépendre du réseau ni d'un vrai
// client Supabase, grâce aux seams AppDatabase.instance / AuthGate.current.

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:mobile_money_tracker/db/app_database.dart';
import 'package:mobile_money_tracker/main.dart';
import 'package:mobile_money_tracker/screens/auth_screen.dart';
import 'package:mobile_money_tracker/services/auth_gate.dart';
import 'package:mobile_money_tracker/services/sync_service.dart';

import 'support/fakes.dart';
import 'support/sample_transaction.dart';

/// SyncService qui compte ses appels start()/stop(), pour vérifier que le
/// cycle de vie de la synchro suit bien les changements d'authentification
/// (voir _RacineAppState._onAuthChanged dans lib/main.dart).
class _CountingSyncService extends SyncService {
  _CountingSyncService({
    required super.db,
    required super.connectivity,
    required super.transport,
  });

  int startCalls = 0;
  int stopCalls = 0;

  @override
  void start() {
    startCalls++;
    super.start();
  }

  @override
  void stop() {
    stopCalls++;
    super.stop();
  }
}

void main() {
  final defaultSyncServiceBuilder = SyncServiceFactory.builder;

  // DashboardScreen (affiché en permanence dans l'IndexedStack de
  // _ShellPrincipal, même hors de l'onglet actif) formate le mois en
  // fr_FR ; sans cette initialisation (faite par main() dans l'app réelle),
  // intl lève LocaleDataException dès que l'écran principal est construit.
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

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

  testWidgets('Utilisateur authentifié, base locale non vide -> écran principal directement', (tester) async {
    await AppDatabase.instance.insertTransactionIfNew(buildTransaction());
    AuthGate.current = FakeAuthGate(authenticated: true);

    await tester.pumpWidget(const MobileMoneyTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Découvrir avec des données de démo'), findsNothing);
    expect(find.text('Rapports'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('Authentification en cours de session -> quitte l\'écran de connexion', (tester) async {
    final fakeAuth = FakeAuthGate(authenticated: false);
    AuthGate.current = fakeAuth;

    await tester.pumpWidget(const MobileMoneyTrackerApp());
    await tester.pump();
    expect(find.byType(AuthScreen), findsOneWidget);

    fakeAuth.setAuthenticated(true);
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsNothing);
    expect(find.text('Découvrir avec des données de démo'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('Déconnexion en cours de session -> retour à l\'écran de connexion', (tester) async {
    final fakeAuth = FakeAuthGate(authenticated: true);
    AuthGate.current = fakeAuth;

    await tester.pumpWidget(const MobileMoneyTrackerApp());
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsNothing);

    fakeAuth.setAuthenticated(false);
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('Connexion démarre SyncService, déconnexion l\'arrête', (tester) async {
    _CountingSyncService? syncService;
    SyncServiceFactory.builder = (db) {
      final s = _CountingSyncService(
        db: db,
        connectivity: FakeConnectivityChecker(online: false),
        transport: AlwaysFailingSyncTransport(),
      );
      syncService = s;
      return s;
    };
    final fakeAuth = FakeAuthGate(authenticated: false);
    AuthGate.current = fakeAuth;

    await tester.pumpWidget(const MobileMoneyTrackerApp());
    await tester.pump();
    // _syncService est un champ `late final` : tant que l'utilisateur n'a
    // jamais été authentifié, il n'est pas encore construit.
    expect(syncService, isNull);

    fakeAuth.setAuthenticated(true);
    await tester.pumpAndSettle();
    expect(syncService!.startCalls, 1);
    expect(syncService!.stopCalls, 0);

    fakeAuth.setAuthenticated(false);
    await tester.pumpAndSettle();
    expect(syncService!.stopCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets(
    'Les données locales survivent à la déconnexion (comportement actuel, pas de purge locale)',
    (tester) async {
      await AppDatabase.instance.insertTransactionIfNew(buildTransaction());
      final fakeAuth = FakeAuthGate(authenticated: true);
      AuthGate.current = fakeAuth;

      await tester.pumpWidget(const MobileMoneyTrackerApp());
      await tester.pumpAndSettle();
      expect(await AppDatabase.instance.countTransactions(), 1);

      fakeAuth.setAuthenticated(false);
      await tester.pump();

      // Se déconnecter arrête la synchro mais ne purge pas la base locale :
      // documente ce comportement actuel plutôt que de le supposer.
      expect(await AppDatabase.instance.countTransactions(), 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    },
  );
}
