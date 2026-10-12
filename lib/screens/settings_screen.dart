import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../parsing/sms_listener.dart';
import '../services/categorization_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';
import 'ai_model_screen.dart';
import 'category_management_screen.dart';
import 'contact_category_screen.dart';

/// Écran Réglages : point d'entrée unique pour tous les réglages de l'app.
/// Volontairement structuré comme une liste d'entrées plutôt qu'un seul
/// formulaire, pour accueillir simplement de futurs réglages.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _scanEnCours = false;

  Future<void> _rescannerSms() async {
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

    setState(() => _scanEnCours = true);
    try {
      final service = SmsListenerService(
        AppDatabase.instance,
        CategorizationService(AppDatabase.instance),
      );

      final autorise = await service.demanderPermissions();
      if (!autorise) {
        if (!mounted) return;
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
                ? '$nouvelles nouvelle(s) transaction(s) trouvée(s) dans vos SMS.'
                : 'Aucune nouvelle transaction trouvée dans vos SMS.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la lecture des SMS : $e')),
      );
    } finally {
      if (mounted) setState(() => _scanEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Réglages'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsRow(
            icon: Icons.sms_outlined,
            title: 'Rescanner les SMS',
            subtitle: _scanEnCours
                ? 'Lecture des SMS en cours...'
                : 'Relire les SMS pour récupérer les transactions manquées',
            trailing: _scanEnCours
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _scanEnCours ? null : _rescannerSms,
          ),
          const SizedBox(height: 12),
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
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

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
              trailing ?? Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
