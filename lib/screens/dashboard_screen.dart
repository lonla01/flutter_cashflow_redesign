import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../models/transaction.dart';
import '../services/export_service.dart';
import '../services/report_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Periode _periode = Periode.semaine;
  DateTime _reference = DateTime.now();
  List<MoneyTransaction> _toutes = [];
  bool _chargement = true;

  static const _couleurs = [
    Colors.blue, Colors.orange, Colors.green, Colors.red, Colors.purple,
    Colors.teal, Colors.brown, Colors.pink, Colors.indigo, Colors.amber,
  ];

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
      _reference = _periode == Periode.semaine
          ? _reference.add(Duration(days: 7 * delta))
          : DateTime(_reference.year, _reference.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) return const Center(child: CircularProgressIndicator());

    final debut = ReportService.debutPeriode(_reference, _periode);
    final fin = ReportService.finPeriode(debut, _periode);
    final transactions = ReportService.filtrerParPeriode(_toutes, debut, fin);
    final parCategorie = ReportService.totauxParCategorie(transactions);
    final parContact = ReportService.totauxParContact(transactions);
    final totalDepenses = ReportService.totalDepenses(transactions);
    final totalEntrees = ReportService.totalEntrees(transactions);
    final montantFmt = NumberFormat('#,##0', 'fr_FR');
    final periodeLabel = _periode == Periode.semaine
        ? 'Semaine du ${DateFormat('dd/MM').format(debut)} au ${DateFormat('dd/MM').format(fin)}'
        : DateFormat('MMMM yyyy', 'fr_FR').format(debut);

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToggleButtons(
                isSelected: [_periode == Periode.semaine, _periode == Periode.mois],
                onPressed: (i) => setState(() {
                  _periode = i == 0 ? Periode.semaine : Periode.mois;
                  _reference = DateTime.now();
                }),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Semaine')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Mois')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => _changerPeriode(-1), icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Text(periodeLabel, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(onPressed: () => _changerPeriode(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _totalCard('Dépensé', totalDepenses, Colors.red.shade700, montantFmt),
                  _totalCard('Reçu', totalEntrees, Colors.green.shade700, montantFmt),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (parCategorie.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Aucune dépense sur cette période.')),
            )
          else ...[
            const Text('Répartition par catégorie', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
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
            ),
            const SizedBox(height: 12),
            ...List.generate(parCategorie.length, (i) {
              final c = parCategorie[i];
              return ListTile(
                dense: true,
                leading: CircleAvatar(radius: 8, backgroundColor: _couleurs[i % _couleurs.length]),
                title: Text(c.categorie),
                trailing: Text('${montantFmt.format(c.total)} FCFA'),
              );
            }),
            const SizedBox(height: 24),

            const Text('Par contact / destinataire', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...parContact.take(10).map((c) => ListTile(
                  dense: true,
                  title: Text(c.contact),
                  trailing: Text('${montantFmt.format(c.total)} FCFA'),
                )),
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

  Widget _totalCard(String label, double montant, Color couleur, NumberFormat fmt) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text('${fmt.format(montant)} FCFA', style: TextStyle(color: couleur, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}
