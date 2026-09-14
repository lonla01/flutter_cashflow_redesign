import 'package:flutter/material.dart';

import 'category_management_screen.dart';

/// Écran Réglages : point d'entrée unique pour tous les réglages de l'app.
/// Volontairement structuré comme une liste d'entrées plutôt qu'un seul
/// formulaire, pour accueillir simplement de futurs réglages.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Catégories'),
            subtitle: const Text('Ajouter ou retirer des catégories de transaction'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CategoryManagementScreen(),
            )),
          ),
        ],
      ),
    );
  }
}
