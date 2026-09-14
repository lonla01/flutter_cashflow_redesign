import 'package:flutter/material.dart';

import '../db/app_database.dart';

/// Réglages > Contacts : associe un contact (nom exact) à une catégorie de
/// façon durable. L'association réassigne immédiatement toutes les
/// transactions existantes de ce contact ET alimente la catégorisation
/// automatique des futures transactions du même contact (voir
/// CategorizationService.suggestCategory).
class ContactCategoryScreen extends StatefulWidget {
  const ContactCategoryScreen({super.key});

  @override
  State<ContactCategoryScreen> createState() => _ContactCategoryScreenState();
}

class _ContactCategoryScreenState extends State<ContactCategoryScreen> {
  List<String> _contacts = [];
  Map<String, String> _categorieParContact = {};
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final contacts = await AppDatabase.instance.getUniqueContactNames();
    final regles = await AppDatabase.instance.getCategoryRules();
    final association = <String, String>{
      for (final r in regles.where((r) => r.matchType == 'contact_nom_contains'))
        r.matchValue.toLowerCase(): r.categorie,
    };
    setState(() {
      _contacts = contacts;
      _categorieParContact = association;
      _chargement = false;
    });
  }

  Future<void> _choisirCategorie(String contact) async {
    final categories = await AppDatabase.instance.watchCategories().first;
    if (!mounted) return;
    final choix = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Catégorie pour "$contact"'),
        children: categories
            .map((c) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(c),
                  child: Text(c),
                ))
            .toList(),
      ),
    );
    if (choix == null) return;

    final nb = await AppDatabase.instance.associateContactWithCategory(contact, choix);
    await _charger();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nb > 0
              ? '"$contact" associé à "$choix" — $nb transaction${nb > 1 ? 's' : ''} mise${nb > 1 ? 's' : ''} à jour.'
              : '"$contact" associé à "$choix".',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(child: Text('Aucun contact dans les transactions.'))
              : ListView.separated(
                  itemCount: _contacts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final categorie = _categorieParContact[contact.toLowerCase()];
                    return ListTile(
                      title: Text(contact),
                      subtitle: Text(categorie ?? 'Aucune catégorie associée'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _choisirCategorie(contact),
                    );
                  },
                ),
    );
  }
}
