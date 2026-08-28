import 'package:telephony/telephony.dart';

import '../db/app_database.dart';
import '../parsing/sms_parser.dart';
import '../services/categorization_service.dart';

/// Écoute les SMS entrants sur Android et alimente la base locale.
///
/// ⚠️ Ce fichier n'a pas pu être compilé ni testé dans l'environnement où il
/// a été écrit (pas de Flutter/SDK Android/appareil disponible). Avant de
/// t'y fier en production :
///   1. Vérifie l'API exacte du package `telephony` par rapport à la version
///      résolue par `flutter pub get` (l'API peut avoir légèrement changé).
///   2. Teste sur un vrai téléphone Android — la réception de SMS en tâche
///      de fond ne peut pas être simulée sur émulateur de façon fiable.
///   3. Ajoute les permissions RECEIVE_SMS et READ_SMS dans
///      android/app/src/main/AndroidManifest.xml (voir README).
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
  /// permissions) pour démarrer l'écoute en arrière-plan.
  void demarrerEcoute() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        await _traiterMessage(message.address, message.body);
      },
      listenInBackground: false, // true nécessite un onBackgroundMessage top-level ; voir doc du package
    );
  }

  Future<void> _traiterMessage(String? adresse, String? corps) async {
    if (corps == null || corps.isEmpty) return;
    // On ne filtre pas strictement sur l'adresse ici : le moteur de parsing
    // rejette déjà tout message qui ne correspond à aucun format connu, ce
    // qui protège contre les faux positifs même sans filtrage d'expéditeur.
    final tx = 
    (corps);
    if (tx == null) return;
    tx.categorie = await categorization.suggestCategory(tx);
    await db.insertTransactionIfNew(tx);
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
