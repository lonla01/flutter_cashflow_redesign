import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';
import 'custom_report_service.dart';
import 'report_service.dart';

class ExportService {
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');
  static final _montantFmt = NumberFormat('#,##0', 'fr_FR');

  /// Nom de fichier sûr à partir d'un libellé libre (nom de contact,
  /// période...) : lettres et chiffres conservés, le reste remplacé par "_".
  static String nomDeFichier(String libelle) => libelle
      .replaceAll(RegExp(r'[^0-9A-Za-zÀ-ÿ]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  static Future<File> exporterCsv(List<MoneyTransaction> transactions, String nomFichier) async {
    final rows = <List<dynamic>>[
      ['Date', 'Source', 'Type', 'Contact', 'Catégorie', 'Montant', 'Frais', 'Notes'],
      ...transactions.map((t) => [
            _dateFmt.format(t.dateTransaction),
            sourceLabel(t.source),
            t.type.name,
            t.contactNom ?? '',
            t.categorie,
            t.montant,
            t.frais,
            t.notes,
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$nomFichier.csv');
    await file.writeAsString(csv);
    return file;
  }

  static Future<File> exporterPdf(
    List<MoneyTransaction> transactions,
    String titre,
    String nomFichier,
  ) async {
    final doc = pw.Document();
    final parCategorie = ReportService.totauxParCategorie(transactions);
    final parContact = ReportService.totauxParContact(transactions).take(10).toList();
    final totalDepenses = ReportService.totalDepenses(transactions);
    final totalEntrees = ReportService.totalEntrees(transactions);

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: titre),
          pw.Paragraph(
            text: 'Total dépensé : ${_montantFmt.format(totalDepenses)} FCFA   |   '
                'Total reçu : ${_montantFmt.format(totalEntrees)} FCFA',
          ),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Par catégorie'),
          pw.TableHelper.fromTextArray(
            headers: ['Catégorie', 'Montant (FCFA)'],
            data: parCategorie
                .map((c) => [c.categorie, _montantFmt.format(c.total)])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Top 10 des contacts/destinataires'),
          pw.TableHelper.fromTextArray(
            headers: ['Contact', 'Montant (FCFA)'],
            data: parContact
                .map((c) => [c.contact, _montantFmt.format(c.total)])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Détail des transactions'),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Contact', 'Catégorie', 'Montant'],
            data: transactions
                .map((t) => [
                      _dateFmt.format(t.dateTransaction),
                      t.contactNom ?? '',
                      t.categorie,
                      // Signé comme dans l'app : "+" entrée, "-" sortie.
                      '${t.montantSigne > 0 ? '+' : '-'}${_montantFmt.format(t.montant)}',
                    ])
                .toList(),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$nomFichier.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static String _signe(double montant) =>
      '${montant > 0 ? '+' : montant < 0 ? '-' : ''}${_montantFmt.format(montant.abs())}';

  static String _libelleCriteres(Set<String> valeurs, String tous) =>
      valeurs.isEmpty ? tous : (valeurs.toList()..sort()).join(', ');

  /// Lignes CSV d'un rapport personnalisé, dans l'ordre du rapport : une
  /// ligne par transaction, avec son groupe et son sous-groupe pour
  /// pouvoir la retrier ou la regrouper dans un tableur.
  static List<List<dynamic>> lignesCsvRapport(CustomReport rapport) {
    final parCategorie = rapport.regroupement == ReportGrouping.categorieContact;
    return [
      [
        parCategorie ? 'Catégorie' : 'Contact',
        parCategorie ? 'Contact' : 'Catégorie',
        'Date',
        'Type',
        'Montant',
        'Frais',
        'Notes',
      ],
      for (final g in rapport.groupes)
        for (final s in g.sousGroupes)
          for (final t in s.transactions)
            [
              g.libelle,
              s.libelle,
              _dateFmt.format(t.dateTransaction),
              typeLabel(t.type),
              t.montantSigne,
              t.frais,
              t.notes,
            ],
    ];
  }

  static Future<File> exporterRapportCsv(CustomReport rapport, String nomFichier) async {
    final csv = const ListToCsvConverter().convert(lignesCsvRapport(rapport));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$nomFichier.csv');
    await file.writeAsString(csv);
    return file;
  }

  static Future<File> exporterRapportPdf(
    CustomReport rapport,
    String titre,
    String nomFichier,
  ) async {
    final c = rapport.criteres;
    final jour = DateFormat('dd/MM/yyyy');
    final parCategorie = rapport.regroupement == ReportGrouping.categorieContact;
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: titre),
          pw.Paragraph(
            text: 'Période : du ${jour.format(c.debut)} au ${jour.format(c.fin)}\n'
                'Catégories : ${_libelleCriteres(c.categories, 'toutes')}\n'
                'Contacts : ${_libelleCriteres(c.contacts, 'tous')}\n'
                'Regroupement : ${parCategorie ? 'catégorie puis contact' : 'contact puis catégorie'}',
          ),
          pw.Paragraph(
            text: '${rapport.nombre} transactions   |   '
                'Dépensé : ${_montantFmt.format(rapport.depense)} FCFA   |   '
                'Reçu : ${_montantFmt.format(rapport.recu)} FCFA   |   '
                'Solde net : ${_signe(rapport.total)} FCFA',
          ),
          for (final g in rapport.groupes) ...[
            pw.Header(level: 1, text: '${g.libelle}   ${_signe(g.total)} FCFA'),
            for (final s in g.sousGroupes) ...[
              pw.Header(level: 2, text: '${s.libelle}   ${_signe(s.total)} FCFA'),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Type', 'Notes', 'Montant'],
                data: s.transactions
                    .map((t) => [
                          _dateFmt.format(t.dateTransaction),
                          typeLabel(t.type),
                          t.notes,
                          _signe(t.montantSigne),
                        ])
                    .toList(),
              ),
              pw.SizedBox(height: 8),
            ],
          ],
          pw.Header(level: 1, text: 'Total   ${_signe(rapport.total)} FCFA'),
        ],
      ),
    );
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$nomFichier.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static Future<void> partager(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }
}
