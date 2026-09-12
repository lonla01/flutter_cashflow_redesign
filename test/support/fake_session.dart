import 'package:gotrue/gotrue.dart';

/// Construit une [Session] minimale mais valide pour les tests : seuls les
/// champs obligatoires de `Session`/`User` sont renseignés, les valeurs
/// elles-mêmes n'ont pas de signification pour les tests d'authentification.
Session fakeSession({String userId = 'user-id'}) => Session(
      accessToken: 'fake-access-token',
      tokenType: 'bearer',
      user: fakeUser(id: userId),
    );

User fakeUser({String id = 'user-id', String? email}) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime(2024, 1, 1).toIso8601String(),
      email: email,
    );
