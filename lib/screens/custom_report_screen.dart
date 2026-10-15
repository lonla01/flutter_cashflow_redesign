import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../models/transaction.dart';
import '../services/custom_report_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';
import 'transaction_detail_screen.dart';

enum _Format { csv, pdf }

final _montantFmt = NumberFormat('#,##0', 'fr_FR');
final _jourFmt = DateFormat('dd/MM/yyyy', 'fr_FR');

String _signe(double montant) =>
    '${montant > 0 ? '+' : montant < 0 ? '-' : ''}${_montantFmt.format(montant.abs())} FCFA';

Color? _couleur(double montant) => montant > 0
    ? Colors.green.shade700
    : montant < 0
        ? Colors.red.shade700
        : null;

/// Rapport personnalisé : période, catégories et contacts choisis
/// librement, transactions regroupées sur deux niveaux (catégorie puis
/// contact, ou l'inverse) avec sous-totaux, exportable en PDF ou CSV.
class CustomReportScreen extends StatefulWidget {
  const CustomReportScreen({super.key, required this.periodeInitiale});

  final DateTimeRange periodeInitiale;

  @override
  State<CustomReportScreen> createState() => _CustomReportScreenState();
}

class _CustomReportScreenState extends State<CustomReportScreen> {
  late DateTimeRange _periode = widget.periodeInitiale;
  Set<String> _categories = {};
  Set<String> _contacts = {};
  ReportGrouping _regroupement = ReportGrouping.categorieContact;

  List<MoneyTransaction> _toutes = [];
  List<String> _categoriesConnues = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final transactions = await AppDatabase.instance.getAllTransactions();
    final categories = await AppDatabase.instance.watchCategories().first;
    if (!mounted) return;
    setState(() {
      _toutes = transactions;
      // Une transaction peut porter une catégorie supprimée depuis.
      _categoriesConnues = {...categories, ...transactions.map((t) => t.categorie)}.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      _chargement = false;
    });
  }

  ReportCriteria get _criteres => ReportCriteria(
        debut: DateTime(_periode.start.year, _periode.start.month, _periode.start.day),
        fin: DateTime(_periode.end.year, _periode.end.month, _periode.end.day + 1)
            .subtract(const Duration(milliseconds: 1)),
        categories: _categories,
        contacts: _contacts,
      );

  String get _libellePeriode => '${_jourFmt.format(_periode.start)} – ${_jourFmt.format(_periode.end)}';

  /// Contacts présents sur la période, plus ceux déjà sélectionnés (qui
  /// peuvent ne plus y figurer après un changement de période).
  List<String> get _contactsDisponibles {
    final c = _criteres;
    return {
      ..._toutes
          .where((t) => !t.dateTransaction.isBefore(c.debut) && !t.dateTransaction.isAfter(c.fin))
          .map(contactDe),
      ..._contacts,
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Future<void> _choisirPeriode() async {
    final choix = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: _periode,
      helpText: 'Période du rapport',
      saveText: 'Appliquer',
      confirmText: 'Appliquer',
    );
    if (choix != null) setState(() => _periode = choix);
  }

  Future<void> _choisir(String titre, List<String> options, Set<String> actuels,
      void Function(Set<String>) appliquer) async {
    final choix = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _MultiSelectDialog(titre: titre, options: options, selection: actuels),
    );
    if (choix != null) setState(() => appliquer(choix));
  }

  Future<void> _exporter(_Format format, CustomReport rapport) async {
    final messenger = ScaffoldMessenger.of(context);
    final nom = ExportService.nomDeFichier('rapport_personnalise_$_libellePeriode');
    try {
      final fichier = format == _Format.csv
          ? await ExportService.exporterRapportCsv(rapport, nom)
          : await ExportService.exporterRapportPdf(rapport, 'Rapport personnalisé', nom);
      await ExportService.partager(fichier);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export impossible : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rapport = _chargement ? null : buildCustomReport(_toutes, _criteres, _regroupement);

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Rapport personnalisé',
        actions: [
          PopupMenuButton<_Format>(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exporter',
            enabled: rapport != null && rapport.nombre > 0,
            onSelected: (f) => _exporter(f, rapport!),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _Format.csv,
                child: ListTile(leading: Icon(Icons.table_chart), title: Text('Exporter en CSV')),
              ),
              PopupMenuItem(
                value: _Format.pdf,
                child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('Exporter en PDF')),
              ),
            ],
          ),
        ],
      ),
      body: rapport == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _criteresCard(),
                const SizedBox(height: 12),
                Center(
                  child: SegmentedButton<ReportGrouping>(
                    segments: const [
                      ButtonSegment(
                        value: ReportGrouping.categorieContact,
                        label: Text('Catégorie → Contact'),
                      ),
                      ButtonSegment(
                        value: ReportGrouping.contactCategorie,
                        label: Text('Contact → Catégorie'),
                      ),
                    ],
                    selected: {_regroupement},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _regroupement = s.single),
                  ),
                ),
                const SizedBox(height: 12),
                _resume(rapport),
                const SizedBox(height: 12),
                if (rapport.nombre == 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('Aucune transaction ne correspond à ces critères.')),
                  )
                else
                  for (final g in rapport.groupes) _groupe(g),
              ],
            ),
    );
  }

  Widget _criteresCard() {
    String resume(Set<String> valeurs, String tous) {
      if (valeurs.isEmpty) return tous;
      final liste = valeurs.toList()..sort();
      final debut = liste.take(3).join(', ');
      return liste.length > 3 ? '$debut et ${liste.length - 3} autre(s)' : debut;
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.date_range),
            title: const Text('Période'),
            subtitle: Text(_libellePeriode),
            trailing: const Icon(Icons.chevron_right),
            onTap: _choisirPeriode,
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Catégories'),
            subtitle: Text(resume(_categories, 'Toutes les catégories')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _choisir(
                'Catégories', _categoriesConnues, _categories, (s) => _categories = s),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Contacts'),
            subtitle: Text(resume(_contacts, 'Tous les contacts')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                _choisir('Contacts', _contactsDisponibles, _contacts, (s) => _contacts = s),
          ),
        ],
      ),
    );
  }

  Widget _resume(CustomReport rapport) {
    Widget chiffre(String label, String valeur, Color couleur) => Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
            const SizedBox(height: 4),
            Text(valeur,
                style: TextStyle(color: couleur, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${rapport.nombre} transaction${rapport.nombre > 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              chiffre('Dépensé', _montantFmt.format(rapport.depense), Colors.redAccent.shade100),
              chiffre('Reçu', _montantFmt.format(rapport.recu), Colors.greenAccent.shade100),
              chiffre(
                'Solde net',
                _signe(rapport.total).replaceAll(' FCFA', ''),
                rapport.total > 0
                    ? Colors.greenAccent.shade100
                    : rapport.total < 0
                        ? Colors.redAccent.shade100
                        : Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _groupe(ReportGroup g) {
    return Card(
      child: ExpansionTile(
        // Clé liée au regroupement : un groupe "Alimentation" n'hérite pas
        // de l'état replié d'un groupe homonyme de l'autre vue.
        key: PageStorageKey('${_regroupement.name}/${g.libelle}'),
        shape: const Border(),
        title: Text(g.libelle, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${g.nombre} transaction${g.nombre > 1 ? 's' : ''}'),
        trailing: Text(
          _signe(g.total),
          style: TextStyle(fontWeight: FontWeight.w700, color: _couleur(g.total)),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [for (final s in g.sousGroupes) _sousGroupe(s)],
      ),
    );
  }

  Widget _sousGroupe(ReportSubGroup s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(s.libelle,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy700)),
            ),
            Text(_signe(s.total),
                style: TextStyle(fontWeight: FontWeight.w600, color: _couleur(s.total))),
          ],
        ),
        for (final t in s.transactions)
          InkWell(
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(transaction: t),
              ));
              _charger();
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 6, bottom: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(_jourFmt.format(t.dateTransaction),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                  ),
                  Expanded(
                    child: Text(
                      t.notes.isNotEmpty ? t.notes : typeLabel(t.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(_signe(t.montantSigne),
                      style: TextStyle(fontSize: 13, color: _couleur(t.montantSigne))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Choix multiple avec recherche. Une sélection vide signifie "tous".
class _MultiSelectDialog extends StatefulWidget {
  const _MultiSelectDialog({
    required this.titre,
    required this.options,
    required this.selection,
  });

  final String titre;
  final List<String> options;
  final Set<String> selection;

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late final Set<String> _selection = {...widget.selection};
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    final visibles = widget.options
        .where((o) => o.toLowerCase().contains(_recherche.toLowerCase()))
        .toList();
    return AlertDialog(
      title: Text(widget.titre),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher...',
                isDense: true,
              ),
              onChanged: (v) => setState(() => _recherche = v),
            ),
            const SizedBox(height: 4),
            Text(
              _selection.isEmpty
                  ? 'Aucune sélection : tout est inclus'
                  : '${_selection.length} sélectionné(s)',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final o in visibles)
                    CheckboxListTile(
                      dense: true,
                      value: _selection.contains(o),
                      title: Text(o),
                      onChanged: (coche) => setState(() {
                        if (coche == true) {
                          _selection.add(o);
                        } else {
                          _selection.remove(o);
                        }
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(_selection.clear),
          child: const Text('Tout inclure'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selection),
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}
