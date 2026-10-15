import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../parsing/sms_listener.dart';
import '../services/categorization_service.dart';
import '../services/momo_statement_import_service.dart';
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
  bool _importEnCours = false;

  Future<void> _importerReleveMomo() async {
    final choix = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final octets = choix?.files.single.bytes;
    if (octets == null) return;

    setState(() => _importEnCours = true);
    try {
      final resume = await MomoStatementImportService(
        AppDatabase.instance,
        CategorizationService(AppDatabase.instance),
      ).importer(octets);
      if (!mounted) return;
      final jour = DateFormat('dd/MM/yyyy');
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Relevé importé'),
          content: Text(
            '${resume.lues} transactions lues, du ${jour.format(resume.debut)} '
            'au ${jour.format(resume.fin)}.\n\n'
            '${resume.importees} ajoutée(s), ${resume.dejaPresentes} déjà présente(s).'
            '${resume.incoherencesSolde > 0 ? '\n\nAttention : ${resume.incoherencesSolde} '
                'incohérence(s) de solde détectée(s), certaines lignes ont peut-être été '
                'mal lues. Vérifiez-les dans la liste.' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Import impossible : $e")),
      );
    } finally {
      if (mounted) setState(() => _importEnCours = false);
    }
  }

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
            icon: Icons.picture_as_pdf_outlined,
            title: 'Importer un relevé MTN MoMo',
            subtitle: _importEnCours
                ? 'Lecture du relevé en cours...'
                : "Relevé PDF exporté depuis l'app MoMo (ex. sur iPhone)",
            trailing: _importEnCours
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _importEnCours ? null : _importerReleveMomo,
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
