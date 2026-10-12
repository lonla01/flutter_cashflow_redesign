import 'dart:async';

import 'package:app_links/app_links.dart';

import '../db/app_database.dart';
import '../parsing/sms_parser.dart';
import '../services/categorization_service.dart';

/// Équivalent iOS de l'écoute SMS native d'Android
/// (voir lib/parsing/sms_listener.dart) : iOS n'expose aucune API, publique
/// ou privée, permettant à une app tierce de lire les SMS. L'utilisateur
/// déclenche donc lui-même l'import via un Raccourci (Shortcuts) qui
/// sélectionne les SMS Mobile Money pertinents et les transmet à l'app par
/// deep link — voir le Raccourci "Importer mes SMS Mobile Money" documenté
/// dans ios/README-shortcuts.md.
///
/// Format du lien attendu :
///   mobilemoneytracker://import-sms?bodies=<texte encodé URL>
/// où `bodies` contient un ou plusieurs corps de SMS, séparés par
/// [_separateur]. Chaque SMS est repassé par le même moteur de parsing et la
/// même dé-duplication (`insertTransactionIfNew`) que le chemin Android, donc
/// réimporter deux fois le même SMS ne crée jamais de doublon.
class SmsImportLinkService {
  SmsImportLinkService(this.db, this.categorization);

  final AppDatabase db;
  final CategorizationService categorization;

  static const hostAttendu = 'import-sms';
  static const separateur = '\n<<<SMS>>>\n';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _abonnement;

  /// À appeler une fois au démarrage de l'app (voir main.dart). Traite aussi
  /// le lien ayant potentiellement lancé l'app à froid (utilisateur qui
  /// ouvre le Raccourci alors que l'app n'était pas en mémoire).
  Future<void> demarrer() async {
    _abonnement = _appLinks.uriLinkStream.listen(_traiterLien);
    final lienInitial = await _appLinks.getInitialLink();
    if (lienInitial != null) await _traiterLien(lienInitial);
  }

  void arreter() => _abonnement?.cancel();

  Future<void> _traiterLien(Uri uri) async {
    // Le même schéma `mobilemoneytracker://` sert aussi au lien de
    // confirmation d'email Supabase (host `login-callback`) : on ignore
    // tout ce qui n'est pas explicitement pour nous.
    if (uri.host != hostAttendu) return;

    final brut = uri.queryParameters['bodies'];
    if (brut == null || brut.isEmpty) return;

    final messages = brut.split(separateur).map((m) => m.trim()).where((m) => m.isNotEmpty);
    for (final corps in messages) {
      final tx = parseSms(corps);
      if (tx == null) continue;
      tx.categorie = await categorization.suggestCategory(tx);
      await db.insertTransactionIfNew(tx);
    }
  }
}
