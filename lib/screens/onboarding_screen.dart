import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/seed_data.dart';
import '../parsing/sms_listener.dart';
import '../services/categorization_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onTermine;
  const OnboardingScreen({super.key, required this.onTermine});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _chargementDemo = false;
  bool _chargementReel = false;

  bool get _chargementEnCours => _chargementDemo || _chargementReel;

  Future<void> _lireSmsReels() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "La lecture des SMS n'est possible que sur un appareil Android réel, pas dans le navigateur.",
          ),
        ),
      );
      return;
    }

    setState(() => _chargementReel = true);
    try {
      final service = SmsListenerService(
        AppDatabase.instance,
        CategorizationService(AppDatabase.instance),
      );

      final autorise = await service.demanderPermissions();
      if (!autorise) {
        if (!mounted) return;
        setState(() => _chargementReel = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Permission refusée : l'app ne peut pas lire vos SMS sans cette autorisation.",
            ),
          ),
        );
        return;
      }

      final nouvelles = await service.scannerHistorique();
      service.demarrerEcoute();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nouvelles > 0
                ? '$nouvelles transaction(s) réelle(s) trouvée(s) dans vos SMS.'
                : "Aucune transaction Mobile Money trouvée dans l'historique de vos SMS.",
          ),
        ),
      );
      widget.onTermine();
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargementReel = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la lecture des SMS : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.account_balance_wallet, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Suivi Mobile Money & Orange Money',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Pour fonctionner automatiquement, l'app a besoin de lire les SMS "
              'reçus de vos opérateurs Mobile Money afin de détecter vos '
              'transactions. Elle ne lit et ne traite que les SMS provenant '
              "d'Orange Money et MTN Mobile Money — aucun autre message n'est "
              'consulté ni transmis.',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'Note : vous pouvez soit lire vos vrais SMS pour afficher vos '
              'transactions réelles, soit découvrir les écrans avec des '
              'données fictives de démonstration.',
              style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _chargementReel
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sms),
                label: Text(_chargementReel ? 'Lecture des SMS...' : 'Lire mes SMS et afficher mes vraies données'),
                onPressed: _chargementEnCours ? null : _lireSmsReels,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: _chargementDemo
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow),
                label: Text(_chargementDemo ? 'Chargement...' : 'Découvrir avec des données de démo'),
                onPressed: _chargementEnCours
                    ? null
                    : () async {
                        setState(() => _chargementDemo = true);
                        await SeedDataService.semerSiVide(AppDatabase.instance);
                        widget.onTermine();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
