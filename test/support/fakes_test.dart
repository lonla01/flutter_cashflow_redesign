// Vérifie que FakeAuthGate se comporte comme l'attend le contrat AuthGate,
// pour que les tests d'écran et de routage qui s'appuient dessus (voir
// test/screens/auth_screen_test.dart et test/widget_test.dart) reposent sur
// un double fidèle.

import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  group('FakeAuthGate', () {
    test('démarre authentifié par défaut', () {
      final gate = FakeAuthGate();
      expect(gate.isAuthenticated, isTrue);
    });

    test('démarre non authentifié quand demandé', () {
      final gate = FakeAuthGate(authenticated: false);
      expect(gate.isAuthenticated, isFalse);
    });

    test('signIn réussi authentifie et émet sur onAuthChanged', () async {
      final gate = FakeAuthGate(authenticated: false);
      expect(
        gate.onAuthChanged,
        emits(true),
      );

      await gate.signIn(email: 'a@b.com', password: 'secret1');

      expect(gate.isAuthenticated, isTrue);
    });

    test('signUp réussi (sans confirmation requise) authentifie et retourne true', () async {
      final gate = FakeAuthGate(authenticated: false);

      final sessionOuverte = await gate.signUp(email: 'a@b.com', password: 'secret1');

      expect(sessionOuverte, isTrue);
      expect(gate.isAuthenticated, isTrue);
    });

    test('signUp avec confirmEmailOnSignUp retourne false et ne connecte pas', () async {
      final gate = FakeAuthGate(authenticated: false, confirmEmailOnSignUp: true);

      final sessionOuverte = await gate.signUp(email: 'a@b.com', password: 'secret1');

      expect(sessionOuverte, isFalse);
      expect(gate.isAuthenticated, isFalse);
    });

    test('signIn avec errorOnSignIn lève l\'erreur et laisse l\'état inchangé', () async {
      final gate = FakeAuthGate(authenticated: false)..errorOnSignIn = Exception('boom');

      await expectLater(
        () => gate.signIn(email: 'a@b.com', password: 'secret1'),
        throwsA(isA<Exception>()),
      );
      expect(gate.isAuthenticated, isFalse);
    });

    test('signUp avec errorOnSignIn lève l\'erreur et laisse l\'état inchangé', () async {
      final gate = FakeAuthGate(authenticated: false)..errorOnSignIn = Exception('boom');

      await expectLater(
        () => gate.signUp(email: 'a@b.com', password: 'secret1'),
        throwsA(isA<Exception>()),
      );
      expect(gate.isAuthenticated, isFalse);
    });

    test('signOut désauthentifie et émet sur onAuthChanged', () async {
      final gate = FakeAuthGate(authenticated: true);
      expect(gate.onAuthChanged, emits(false));

      await gate.signOut();

      expect(gate.isAuthenticated, isFalse);
    });
  });
}
