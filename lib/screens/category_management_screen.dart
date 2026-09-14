import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/gradient_fab.dart';

/// Gestion des catégories proposées dans l'app (filtres, sélecteur de
/// transaction). Supprimer une catégorie ici ne touche jamais les
/// transactions qui l'utilisent déjà : `categorie` reste une simple chaîne
/// libre sur la transaction (voir Categories dans lib/db/tables.dart).
class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  Future<void> _ajouter(BuildContext context) async {
    final controller = TextEditingController();
    final nom = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (nom != null && nom.trim().isNotEmpty) {
      await AppDatabase.instance.addCategory(nom.trim());
    }
  }

  Future<void> _supprimer(BuildContext context, String nom, int nbCategories) async {
    if (nbCategories <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il doit rester au moins une catégorie.')),
      );
      return;
    }
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette catégorie ?'),
        content: Text(
          '"$nom" ne sera plus proposée. Les transactions déjà classées dans '
          'cette catégorie ne seront pas modifiées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirme == true) {
      await AppDatabase.instance.removeCategory(nom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Catégories'),
      body: StreamBuilder<List<String>>(
        stream: AppDatabase.instance.watchCategories(),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? const [];
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (categories.isEmpty) {
            return const Center(child: Text('Aucune catégorie.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final categorie = categories[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.navy700.withValues(alpha: 0.1),
                    child: const Icon(Icons.sell_outlined, color: AppColors.navy700, size: 18),
                  ),
                  title: Text(categorie, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                    tooltip: 'Supprimer',
                    onPressed: () => _supprimer(context, categorie, categories.length),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: GradientFab(
        onPressed: () => _ajouter(context),
        tooltip: 'Nouvelle catégorie',
      ),
    );
  }
}
