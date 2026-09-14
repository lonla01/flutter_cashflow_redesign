import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../models/transaction.dart';
import '../services/export_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _reference = DateTime.now();
  List<MoneyTransaction> _toutes = [];
  bool _chargement = true;
  // null = aucun filtre (toutes les catégories du mois sont incluses).
  Set<String>? _categoriesFiltre;

  static const _couleurs = categoryChartColors;

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
      _chargement = false;
    });
  }

  void _changerPeriode(int delta) {
    setState(() {
      _reference = DateTime(_reference.year, _reference.month + delta, 1);
      // Un filtre construit pour un mois n'a pas vocation à survivre au
      // changement de mois : les catégories présentes peuvent être
      // différentes d'un mois à l'autre.
      _categoriesFiltre = null;
    });
  }

  /// Ouvre le sélecteur de catégories à inclure dans le rapport du mois
  /// affiché. [categoriesDuMois] est la liste complète des catégories
  /// présentes ce mois-ci, indépendamment du filtre déjà appliqué (pour
  /// pouvoir toujours réintégrer une catégorie précédemment décochée).
  Future<void> _filtrerCategories(List<String> categoriesDuMois) async {
    final selection = Set<String>.of(_categoriesFiltre ?? categoriesDuMois);

    final resultat = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Catégories à inclure'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: categoriesDuMois
                  .map((c) => CheckboxListTile(
                        value: selection.contains(c),
                        title: Text(c),
                        onChanged: (coche) => setDialogState(() {
                          if (coche == true) {
                            selection.add(c);
                          } else {
                            selection.remove(c);
                          }
                        }),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => setDialogState(() => selection
                ..clear()
                ..addAll(categoriesDuMois)),
              child: const Text('Tout sélectionner'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selection),
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
    if (resultat == null) return;

    setState(() {
      // Tout sélectionné revient à "pas de filtre", pour rester cohérent
      // si le mois affiché change ensuite.
      _categoriesFiltre = resultat.length == categoriesDuMois.length ? null : resultat;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) return const Center(child: CircularProgressIndicator());

    final debut = ReportService.debutPeriode(_reference);
    final fin = ReportService.finPeriode(debut);
    final transactionsDuMois = ReportService.filtrerParPeriode(_toutes, debut, fin);
    final categoriesDuMois = transactionsDuMois.map((t) => t.categorie).toSet().toList()..sort();
    final transactions = _categoriesFiltre == null
        ? transactionsDuMois
        : transactionsDuMois.where((t) => _categoriesFiltre!.contains(t.categorie)).toList();
    final parCategorie = ReportService.totauxParCategorie(transactions);
    final parContact = ReportService.totauxParContact(transactions);
    final totalDepenses = ReportService.totalDepenses(transactions);
    final totalEntrees = ReportService.totalEntrees(transactions);
    final montantFmt = NumberFormat('#,##0', 'fr_FR');
    final periodeLabel = DateFormat('MMMM yyyy', 'fr_FR').format(debut);

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _flecheMois(Icons.chevron_left, () => _changerPeriode(-1)),
                Text(
                  _capitaliser(periodeLabel),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                    letterSpacing: 0.2,
                  ),
                ),
                _flecheMois(Icons.chevron_right, () => _changerPeriode(1)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_categoriesFiltre != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InputChip(
                    label: Text('${_categoriesFiltre!.length}/${categoriesDuMois.length} catégories'),
                    onDeleted: () => setState(() => _categoriesFiltre = null),
                  ),
                ),
              TextButton.icon(
                onPressed: categoriesDuMois.isEmpty ? null : () => _filtrerCategories(categoriesDuMois),
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('Filtrer les catégories'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy700.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _totalCard('Dépensé', totalDepenses, Icons.arrow_upward, Colors.redAccent.shade100, montantFmt),
                Container(width: 1, height: 40, color: Colors.white24),
                _totalCard('Reçu', totalEntrees, Icons.arrow_downward, Colors.greenAccent.shade100, montantFmt),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (parCategorie.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Aucune dépense sur cette période.')),
            )
          else ...[
            Text('Répartition par catégorie', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // fl_chart ne permet pas de dégradé pour
                          // centerSpaceColor : on dessine le disque central
                          // nous-mêmes, révélé par le trou transparent du
                          // donut par-dessus.
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppGradients.primary,
                            ),
                          ),
                          PieChart(
                            PieChartData(
                              centerSpaceRadius: 50,
                              centerSpaceColor: Colors.transparent,
                              sections: [
                                for (var i = 0; i < parCategorie.length; i++)
                                  PieChartSectionData(
                                    value: parCategorie[i].total,
                                    title: '',
                                    color: _couleurs[i % _couleurs.length],
                                    radius: 70,
                                  ),
                              ],
                              sectionsSpace: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(parCategorie.length, (i) {
                      final c = parCategorie[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(radius: 8, backgroundColor: _couleurs[i % _couleurs.length]),
                        title: Text(c.categorie, style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Text(
                          '${montantFmt.format(c.total)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Par contact / destinataire', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: parContact
                      .take(10)
                      .map((c) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(c.contact, style: const TextStyle(fontWeight: FontWeight.w500)),
                            trailing: Text(
                              '${montantFmt.format(c.total)} FCFA',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: transactions.isEmpty
                      ? null
                      : () async {
                          final f = await ExportService.exporterCsv(transactions, 'rapport_${DateFormat('yyyyMMdd').format(debut)}');
                          await ExportService.partager(f);
                        },
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export CSV'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: transactions.isEmpty
                      ? null
                      : () async {
                          final f = await ExportService.exporterPdf(
                            transactions,
                            'Rapport - $periodeLabel',
                            'rapport_${DateFormat('yyyyMMdd').format(debut)}',
                          );
                          await ExportService.partager(f);
                        },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitaliser(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Widget _flecheMois(IconData icon, VoidCallback onTap) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.navy700.withValues(alpha: 0.1),
        foregroundColor: AppColors.navy700,
      ),
    );
  }

  Widget _totalCard(String label, double montant, IconData icon, Color accent, NumberFormat fmt) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${fmt.format(montant)} FCFA',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ],
    );
  }
}
