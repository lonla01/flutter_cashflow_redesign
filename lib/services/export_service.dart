import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';
import 'report_service.dart';

class ExportService {
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');
  static final _montantFmt = NumberFormat('#,##0', 'fr_FR');

  static Future<File> exporterCsv(List<MoneyTransaction> transactions, String nomFichier) async {
    final rows = <List<dynamic>>[
      ['Date', 'Source', 'Type', 'Contact', 'Catégorie', 'Montant', 'Frais', 'Notes'],
      ...transactions.map((t) => [
            _dateFmt.format(t.dateTransaction),
            t.source == TransactionSource.orangeMoney ? 'Orange Money' : 'MTN Mobile Money',
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
          pw.Table.fromTextArray(
            headers: ['Catégorie', 'Montant (FCFA)'],
            data: parCategorie
                .map((c) => [c.categorie, _montantFmt.format(c.total)])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Top 10 des contacts/destinataires'),
          pw.Table.fromTextArray(
            headers: ['Contact', 'Montant (FCFA)'],
            data: parContact
                .map((c) => [c.contact, _montantFmt.format(c.total)])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Détail des transactions'),
          pw.Table.fromTextArray(
            headers: ['Date', 'Contact', 'Catégorie', 'Montant'],
            data: transactions
                .map((t) => [
                      _dateFmt.format(t.dateTransaction),
                      t.contactNom ?? '',
                      t.categorie,
                      _montantFmt.format(t.montant),
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

  static Future<void> partager(File file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }
}
