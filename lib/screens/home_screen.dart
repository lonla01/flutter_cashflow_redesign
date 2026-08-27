import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models/category_rule.dart';
import '../models/transaction.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MoneyTransaction> _toutes = [];
  List<MoneyTransaction> _filtrees = [];
  String? _categorieFiltre;
  String _recherche = '';
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final transactions = await AppDatabase.instance.getAllTransactions();
    setState(() {
      _toutes = transactions;
      _appliquerFiltres();
      _chargement = false;
    });
  }

  void _appliquerFiltres() {
    _filtrees = _toutes.where((t) {
      final matchCategorie = _categorieFiltre == null || t.categorie == _categorieFiltre;
      final matchRecherche = _recherche.isEmpty ||
          (t.contactNom ?? '').toLowerCase().contains(_recherche.toLowerCase());
      return matchCategorie && matchRecherche;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher un contact...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() {
              _recherche = v;
              _appliquerFiltres();
            }),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _chipCategorie(null, 'Toutes'),
              ...categoriesParDefaut.map((c) => _chipCategorie(c, c)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _chargement
              ? const Center(child: CircularProgressIndicator())
              : _filtrees.isEmpty
                  ? const Center(child: Text('Aucune transaction pour ce filtre.'))
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.separated(
                        itemCount: _filtrees.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = _filtrees[index];
                          return TransactionTile(
                            transaction: tx,
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => TransactionDetailScreen(transaction: tx),
                              ));
                              _charger();
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _chipCategorie(String? categorie, String label) {
    final selectionne = _categorieFiltre == categorie;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selectionne,
        onSelected: (_) => setState(() {
          _categorieFiltre = categorie;
          _appliquerFiltres();
        }),
      ),
    );
  }
}
