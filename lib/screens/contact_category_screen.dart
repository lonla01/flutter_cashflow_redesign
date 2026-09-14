import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';

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
      appBar: const GradientAppBar(title: 'Contacts'),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? const Center(child: Text('Aucun contact dans les transactions.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final categorie = _categorieParContact[contact.toLowerCase()];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.navy700,
                          child: Text(
                            contact.trim().isNotEmpty ? contact.trim()[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(contact, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: categorie == null
                            ? Text('Aucune catégorie associée', style: TextStyle(color: Colors.grey.shade500))
                            : Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.navy700.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    categorie,
                                    style: const TextStyle(
                                      color: AppColors.navy700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                        onTap: () => _choisirCategorie(contact),
                      ),
                    );
                  },
                ),
    );
  }
}
