// Tests de l'écran de connexion/inscription : validation de formulaire,
// bascule connexion/inscription, appel du bon AuthGate.current.signIn/signUp,
// affichage des erreurs et de l'état "email de confirmation envoyé".

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_tracker/screens/auth_screen.dart';
import 'package:mobile_money_tracker/services/auth_gate.dart';
import 'package:mobile_money_tracker/widgets/gradient_button.dart';

import '../support/fakes.dart';

/// AuthGate dont signIn/signUp restent en attente tant que [resolve] n'a pas
/// été appelé, pour pouvoir observer l'état de chargement de l'écran sans
/// dépendre du timing réel (FakeAuthGate se résout en une seule micro-tâche,
/// trop rapide pour être observée entre deux `pump()`).
class _PendingAuthGate implements AuthGate {
  final _completer = Completer<void>();
  final _controller = StreamController<bool>.broadcast();
  bool _authenticated = false;

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Stream<bool> get onAuthChanged => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _completer.future;
    _authenticated = true;
    _controller.add(true);
  }

  @override
  Future<bool> signUp({required String email, required String password}) async {
    await _completer.future;
    return true;
  }

  @override
  Future<void> signOut() async {}

  void resolve() => _completer.complete();
}

void main() {
  late FakeAuthGate fakeAuth;

  setUp(() {
    fakeAuth = FakeAuthGate(authenticated: false);
    AuthGate.current = fakeAuth;
  });

  Future<void> pumpAuthScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
  }

  Future<void> remplirFormulaire(
    WidgetTester tester, {
    String email = 'a@b.com',
    String motDePasse = 'secret1',
  }) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Mot de passe'), motDePasse);
  }

  testWidgets('mode connexion par défaut, bascule vers inscription et retour', (tester) async {
    await pumpAuthScreen(tester);

    expect(find.text('Content de vous revoir'), findsOneWidget);
    expect(find.widgetWithText(GradientButton, 'Se connecter'), findsOneWidget);

    await tester.tap(find.text('Pas de compte ? Créer un compte'));
    await tester.pump();

    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.widgetWithText(GradientButton, 'Créer le compte'), findsOneWidget);

    await tester.tap(find.text('Déjà un compte ? Se connecter'));
    await tester.pump();

    expect(find.text('Content de vous revoir'), findsOneWidget);
  });

  testWidgets('email invalide bloque la soumission', (tester) async {
    await pumpAuthScreen(tester);
    await remplirFormulaire(tester, email: 'pas-un-email');

    await tester.tap(find.widgetWithText(GradientButton, 'Se connecter'));
    await tester.pump();

    expect(find.text('Email invalide'), findsOneWidget);
  });

  testWidgets('mot de passe trop court bloque la soumission', (tester) async {
    await pumpAuthScreen(tester);
    await remplirFormulaire(tester, motDePasse: '123');

    await tester.tap(find.widgetWithText(GradientButton, 'Se connecter'));
    await tester.pump();

    expect(find.text('Au moins 6 caractères'), findsOneWidget);
  });

  testWidgets('soumission valide en mode connexion authentifie via AuthGate.current', (tester) async {
    await pumpAuthScreen(tester);
    await remplirFormulaire(tester, email: '  a@b.com  ', motDePasse: 'secret1');

    await tester.tap(find.widgetWithText(GradientButton, 'Se connecter'));
    await tester.pumpAndSettle();

    expect(fakeAuth.isAuthenticated, isTrue);
    expect(find.text('Email invalide'), findsNothing);
  });

  testWidgets('soumission valide en mode inscription (session ouverte) authentifie', (tester) async {
    await pumpAuthScreen(tester);
    await tester.tap(find.text('Pas de compte ? Créer un compte'));
    await tester.pump();
    await remplirFormulaire(tester);

    await tester.tap(find.widgetWithText(GradientButton, 'Créer le compte'));
    await tester.pumpAndSettle();

    expect(fakeAuth.isAuthenticated, isTrue);
  });

  testWidgets('affiche le spinner et désactive le bouton pendant la validation', (tester) async {
    final pendingAuth = _PendingAuthGate();
    AuthGate.current = pendingAuth;
    await pumpAuthScreen(tester);
    await remplirFormulaire(tester);

    await tester.tap(find.widgetWithText(GradientButton, 'Se connecter'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<GradientButton>(find.byType(GradientButton));
    expect(button.onPressed, isNull);

    pendingAuth.resolve();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    final buttonApres = tester.widget<GradientButton>(find.byType(GradientButton));
    expect(buttonApres.onPressed, isNotNull);
  });

  testWidgets('erreur de connexion affiche le message et réactive le formulaire', (tester) async {
    fakeAuth.errorOnSignIn = Exception('Invalid login credentials');
    await pumpAuthScreen(tester);
    await remplirFormulaire(tester);

    await tester.tap(find.widgetWithText(GradientButton, 'Se connecter'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Invalid login credentials'), findsOneWidget);
    expect(fakeAuth.isAuthenticated, isFalse);
    final button = tester.widget<GradientButton>(find.byType(GradientButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('inscription avec confirmation requise affiche l\'écran "confirmez votre email"', (tester) async {
    fakeAuth.confirmEmailOnSignUp = true;
    await pumpAuthScreen(tester);
    await tester.tap(find.text('Pas de compte ? Créer un compte'));
    await tester.pump();
    await remplirFormulaire(tester, email: 'nouveau@b.com');

    await tester.tap(find.widgetWithText(GradientButton, 'Créer le compte'));
    await tester.pumpAndSettle();

    expect(fakeAuth.isAuthenticated, isFalse);
    expect(find.text('Confirmez votre email'), findsOneWidget);
    expect(find.textContaining('nouveau@b.com'), findsOneWidget);
  });

  testWidgets('"Retour à la connexion" ramène au formulaire de connexion', (tester) async {
    fakeAuth.confirmEmailOnSignUp = true;
    await pumpAuthScreen(tester);
    await tester.tap(find.text('Pas de compte ? Créer un compte'));
    await tester.pump();
    await remplirFormulaire(tester);
    await tester.tap(find.widgetWithText(GradientButton, 'Créer le compte'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(GradientButton, 'Retour à la connexion'));
    await tester.pump();

    expect(find.text('Content de vous revoir'), findsOneWidget);
    expect(find.text('Confirmez votre email'), findsNothing);
  });
}
