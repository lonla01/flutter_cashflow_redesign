import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
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
  final Set<String> _selection = {};
  final ScrollController _scrollController = ScrollController();

  bool get _modeSelection => _selection.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _basculerSelection(String id) {
    setState(() {
      if (!_selection.remove(id)) _selection.add(id);
    });
  }

  void _annulerSelection() => setState(_selection.clear);

  Future<void> _changerCategorieSelection() async {
    final categories = await AppDatabase.instance.watchCategories().first;
    if (!mounted) return;
    final choix = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Déplacer vers...'),
        children: categories
            .map((c) => SimpleDialogOption(
                  onPressed: () => Navigator.of(context).pop(c),
                  child: Text(c),
                ))
            .toList(),
      ),
    );
    if (choix == null) return;

    final ids = _selection.toList();
    final nb = await AppDatabase.instance.bulkSetCategory(ids, choix);
    _annulerSelection();
    await _charger();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nb transaction${nb > 1 ? 's' : ''} déplacée${nb > 1 ? 's' : ''} vers "$choix".')),
    );
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
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher un contact...',
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
          child: StreamBuilder<List<String>>(
            stream: AppDatabase.instance.watchCategories(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const [];
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _chipCategorie(null, 'Toutes'),
                  ...categories.map((c) => _chipCategorie(c, c)),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _chargement
              ? const Center(child: CircularProgressIndicator())
              : _filtrees.isEmpty
                  ? const Center(child: Text('Aucune transaction pour ce filtre.'))
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: RefreshIndicator(
                        onRefresh: _charger,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _filtrees.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = _filtrees[index];
                            return TransactionTile(
                              transaction: tx,
                              modeSelection: _modeSelection,
                              selectionnee: _selection.contains(tx.id),
                              onLongPress: () => _basculerSelection(tx.id),
                              onTap: () async {
                                if (_modeSelection) {
                                  _basculerSelection(tx.id);
                                  return;
                                }
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
        ),
        if (_modeSelection) _barreSelection(),
      ],
    );
  }

  Widget _barreSelection() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        boxShadow: [BoxShadow(color: Color(0x552A4C86), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Annuler la sélection',
                onPressed: _annulerSelection,
              ),
              Expanded(
                child: Text(
                  '${_selection.length} sélectionnée${_selection.length > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: _changerCategorieSelection,
                icon: const Icon(Icons.drive_file_move_outline, color: Colors.white),
                label: const Text('Changer catégorie', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipCategorie(String? categorie, String label) {
    final selectionne = _categorieFiltre == categorie;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: selectionne ? Colors.white : null)),
        selected: selectionne,
        onSelected: (_) => setState(() {
          _categorieFiltre = categorie;
          _appliquerFiltres();
        }),
      ),
    );
  }
}
