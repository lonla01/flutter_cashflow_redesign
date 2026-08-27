import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/seed_data.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onTermine;
  const OnboardingScreen({super.key, required this.onTermine});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _chargementDemo = false;

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
              'Note : ce MVP est pré-rempli avec des transactions fictives de '
              'démonstration pour vous permettre de découvrir les écrans '
              'immédiatement, en attendant la connexion de la lecture SMS '
              'réelle sur votre appareil.',
              style: TextStyle(fontSize: 13, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _chargementDemo
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow),
                label: Text(_chargementDemo ? 'Chargement...' : 'Découvrir avec des données de démo'),
                onPressed: _chargementDemo
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
