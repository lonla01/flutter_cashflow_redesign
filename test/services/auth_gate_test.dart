// Tests unitaires de SupabaseAuthGate, la seule implémentation d'AuthGate
// qui parle réellement à Supabase. Le GoTrueClient est simulé avec mocktail
// grâce à l'injection de dépendance ajoutée dans lib/services/auth_gate.dart
// (SupabaseAuthGate({GoTrueClient? auth})) : aucun appel réseau, aucun besoin
// de Supabase.initialize().

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gotrue/gotrue.dart';
import 'package:mobile_money_tracker/config/supabase_config.dart';
import 'package:mobile_money_tracker/services/auth_gate.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fake_session.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockGoTrueClient mockAuth;
  late SupabaseAuthGate gate;

  setUpAll(() {
    // Requis par mocktail pour any()/captureAny() sur updateUser.
    registerFallbackValue(UserAttributes());
  });

  setUp(() {
    mockAuth = MockGoTrueClient();
    gate = SupabaseAuthGate(auth: mockAuth);
  });

  group('isAuthenticated', () {
    test('true quand une session est active', () {
      when(() => mockAuth.currentSession).thenReturn(fakeSession());
      expect(gate.isAuthenticated, isTrue);
    });

    test('false quand il n\'y a pas de session', () {
      when(() => mockAuth.currentSession).thenReturn(null);
      expect(gate.isAuthenticated, isFalse);
    });
  });

  group('onAuthChanged', () {
    test('émet true/false selon la présence d\'une session dans chaque événement', () {
      final controller = StreamController<AuthState>();
      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => controller.stream);

      expect(
        gate.onAuthChanged,
        emitsInOrder(<bool>[true, false, true]),
      );

      controller
        ..add(AuthState(AuthChangeEvent.signedIn, fakeSession()))
        ..add(const AuthState(AuthChangeEvent.signedOut, null))
        ..add(AuthState(AuthChangeEvent.tokenRefreshed, fakeSession()));
      controller.close();
    });
  });

  group('signIn', () {
    test('appelle signInWithPassword avec exactement l\'email et le mot de passe fournis', () async {
      when(() => mockAuth.signInWithPassword(email: 'a@b.com', password: 's3cret!'))
          .thenAnswer((_) async => AuthResponse(session: fakeSession()));

      await gate.signIn(email: 'a@b.com', password: 's3cret!');

      verify(() => mockAuth.signInWithPassword(email: 'a@b.com', password: 's3cret!'))
          .called(1);
    });

    test('propage une AuthException levée par GoTrueClient', () {
      when(() => mockAuth.signInWithPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => gate.signIn(email: 'a@b.com', password: 'mauvais'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('signUp', () {
    test('appelle signUp avec email, mot de passe et emailRedirectTo', () async {
      when(
        () => mockAuth.signUp(
          email: 'nouveau@b.com',
          password: 's3cret!',
          emailRedirectTo: SupabaseConfig.authRedirectUrl,
        ),
      ).thenAnswer((_) async => AuthResponse(session: fakeSession()));

      await gate.signUp(email: 'nouveau@b.com', password: 's3cret!');

      verify(
        () => mockAuth.signUp(
          email: 'nouveau@b.com',
          password: 's3cret!',
          emailRedirectTo: SupabaseConfig.authRedirectUrl,
        ),
      ).called(1);
    });

    test('retourne true quand la réponse contient une session (confirmation désactivée)', () async {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenAnswer((_) async => AuthResponse(session: fakeSession()));

      final sessionOuverte = await gate.signUp(email: 'a@b.com', password: 's3cret!');

      expect(sessionOuverte, isTrue);
    });

    test('retourne false quand la réponse ne contient pas de session (email de confirmation envoyé)', () async {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenAnswer((_) async => AuthResponse(session: null, user: fakeUser()));

      final sessionOuverte = await gate.signUp(email: 'a@b.com', password: 's3cret!');

      expect(sessionOuverte, isFalse);
    });

    test('propage une AuthException levée par GoTrueClient', () {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenThrow(const AuthException('User already registered'));

      expect(
        () => gate.signUp(email: 'a@b.com', password: 's3cret!'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('signOut', () {
    test('appelle GoTrueClient.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await gate.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });

    test('propage une erreur levée par GoTrueClient', () {
      when(() => mockAuth.signOut()).thenThrow(const AuthException('network error'));

      expect(() => gate.signOut(), throwsA(isA<AuthException>()));
    });
  });

  group('resetPasswordForEmail', () {
    test('appelle resetPasswordForEmail avec l\'email et authRedirectUrl', () async {
      when(
        () => mockAuth.resetPasswordForEmail('a@b.com', redirectTo: SupabaseConfig.authRedirectUrl),
      ).thenAnswer((_) async {});

      await gate.resetPasswordForEmail('a@b.com');

      verify(
        () => mockAuth.resetPasswordForEmail('a@b.com', redirectTo: SupabaseConfig.authRedirectUrl),
      ).called(1);
    });

    test('propage une AuthException levée par GoTrueClient', () {
      when(() => mockAuth.resetPasswordForEmail(any(), redirectTo: any(named: 'redirectTo')))
          .thenThrow(const AuthException('over_email_send_rate_limit'));

      expect(
        () => gate.resetPasswordForEmail('a@b.com'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('updatePassword', () {
    test('appelle updateUser avec le nouveau mot de passe', () async {
      when(() => mockAuth.updateUser(any()))
          .thenAnswer((_) async => UserResponse.fromJson(fakeUser().toJson()));

      await gate.updatePassword('nouveauMotDePasse1');

      final captured = verify(() => mockAuth.updateUser(captureAny())).captured;
      expect((captured.single as UserAttributes).password, 'nouveauMotDePasse1');
    });

    test('propage une AuthException levée par GoTrueClient (session de récupération expirée)', () {
      when(() => mockAuth.updateUser(any())).thenThrow(const AuthException('invalid JWT'));

      expect(
        () => gate.updatePassword('nouveauMotDePasse1'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('onPasswordRecovery', () {
    test('émet uniquement sur AuthChangeEvent.passwordRecovery, pas les autres événements', () {
      final controller = StreamController<AuthState>();
      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => controller.stream);

      // Un seul événement doit passer le filtre (le passwordRecovery), les
      // deux autres doivent être ignorés : emitsInOrder échouerait si
      // signedIn/signedOut fuitaient aussi à travers le `.where()`.
      expect(gate.onPasswordRecovery, emitsInOrder([anything, emitsDone]));

      controller
        ..add(AuthState(AuthChangeEvent.signedIn, fakeSession()))
        ..add(AuthState(AuthChangeEvent.passwordRecovery, fakeSession()))
        ..add(const AuthState(AuthChangeEvent.signedOut, null));
      controller.close();
    });
  });
}
