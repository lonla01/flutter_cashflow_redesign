import 'package:flutter/material.dart';

import '../db/app_database.dart';

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
      appBar: AppBar(title: const Text('Catégories')),
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
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final categorie = categories[index];
              return ListTile(
                title: Text(categorie),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Supprimer',
                  onPressed: () => _supprimer(context, categorie, categories.length),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ajouter(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
