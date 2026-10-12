import 'package:another_telephony/telephony.dart';

import '../db/app_database.dart';
import '../parsing/sms_parser.dart';
import '../services/categorization_service.dart';

/// Traite un SMS entrant (reçu au premier plan ou en arrière-plan) et
/// l'ajoute à la base locale si c'est une transaction Mobile Money.
/// Fonction top-level réutilisée par [SmsListenerService.demarrerEcoute]
/// pour les deux cas, avec sa propre instance d'[AppDatabase] : voir
/// [traiterMessageEnArrierePlan] pour pourquoi c'est nécessaire en arrière-plan.
Future<void> _traiterMessageAvec(AppDatabase db, String? corps) async {
  if (corps == null || corps.isEmpty) return;
  // On ne filtre pas strictement sur l'adresse ici : le moteur de parsing
  // rejette déjà tout message qui ne correspond à aucun format connu, ce
  // qui protège contre les faux positifs même sans filtrage d'expéditeur.
  final tx = parseSms(corps);
  if (tx == null) return;
  tx.categorie = await CategorizationService(db).suggestCategory(tx);
  await db.insertTransactionIfNew(tx);
}

/// Handler appelé par le plugin `telephony` quand un SMS arrive alors que
/// l'app est en arrière-plan ou fermée. Tourne dans un isolate Dart séparé
/// et frais (aucun état de l'isolate principal n'est partagé) : on ne peut
/// donc pas réutiliser `AppDatabase.instance` tel quel, mais comme c'est un
/// simple champ statique lazy pointant vers le même fichier SQLite sur
/// disque, l'utiliser ici recrée transparemment une connexion équivalente
/// dans cet isolate. Doit rester une fonction top-level (exigence du
/// plugin, voir sa doc) et annotée `vm:entry-point` pour survivre au
/// tree-shaking en mode release.
@pragma('vm:entry-point')
Future<void> traiterMessageEnArrierePlan(SmsMessage message) async {
  await _traiterMessageAvec(AppDatabase.instance, message.body);
}

/// Écoute les SMS entrants sur Android et alimente la base locale.
class SmsListenerService {
  final Telephony telephony = Telephony.instance;
  final AppDatabase db;
  final CategorizationService categorization;

  SmsListenerService(this.db, this.categorization);

  /// Filtre : n'écouter que les expéditeurs Orange Money / MTN MoMo connus.
  /// À ajuster avec les sender ID réels observés sur le terrain.
  static const List<String> expediteursSuivis = [
    'OrangeMoney',
    'ORANGE',
    'MTN',
    'MTNMoMo',
  ];

  Future<bool> demanderPermissions() async {
    final granted = await telephony.requestPhoneAndSmsPermissions;
    return granted ?? false;
  }

  /// À appeler une fois au démarrage de l'app (après obtention des
  /// permissions) pour démarrer l'écoute en arrière-plan. `listenInBackground:
  /// true` fait que les SMS reçus app fermée ou minimisée sont aussi captés,
  /// via [traiterMessageEnArrierePlan] exécuté dans un isolate séparé par le
  /// plugin — sans ça, seuls les SMS reçus pendant que l'app est au premier
  /// plan étaient détectés (voir aussi l'action "Rescanner les SMS" dans les
  /// Réglages, pour rattraper ce que l'écoute en direct aurait manqué).
  void demarrerEcoute() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        await _traiterMessageAvec(db, message.body);
      },
      onBackgroundMessage: traiterMessageEnArrierePlan,
    );
  }

  /// Scan optionnel de l'historique SMS existant sur le téléphone, proposé
  /// à l'utilisateur au premier lancement (voir OnboardingScreen).
  Future<int> scannerHistorique() async {
    final messages = await telephony.getInboxSms();
    var nouvelles = 0;
    for (final m in messages) {
      final tx = parseSms(m.body ?? '');
      if (tx == null) continue;
      tx.categorie = await categorization.suggestCategory(tx);
      final ajoutee = await db.insertTransactionIfNew(tx);
      if (ajoutee) nouvelles++;
    }
    return nouvelles;
  }
}
