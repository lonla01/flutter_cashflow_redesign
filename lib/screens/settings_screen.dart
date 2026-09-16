import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';
import 'ai_model_screen.dart';
import 'category_management_screen.dart';
import 'contact_category_screen.dart';

/// Écran Réglages : point d'entrée unique pour tous les réglages de l'app.
/// Volontairement structuré comme une liste d'entrées plutôt qu'un seul
/// formulaire, pour accueillir simplement de futurs réglages.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Réglages'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsRow(
            icon: Icons.category_outlined,
            title: 'Catégories',
            subtitle: 'Ajouter ou retirer des catégories de transaction',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CategoryManagementScreen(),
            )),
          ),
          const SizedBox(height: 12),
          _SettingsRow(
            icon: Icons.contacts_outlined,
            title: 'Contacts',
            subtitle: 'Associer un contact à une catégorie',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ContactCategoryScreen(),
            )),
          ),
          const SizedBox(height: 12),
          _SettingsRow(
            icon: Icons.smart_toy_outlined,
            title: 'Modèle IA',
            subtitle: 'Choisir le modèle utilisé pour scanner les reçus',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AiModelScreen(),
            )),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.navy700.withValues(alpha: 0.1),
                child: Icon(icon, color: AppColors.navy700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
