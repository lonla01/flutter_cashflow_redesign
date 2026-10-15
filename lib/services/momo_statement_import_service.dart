import 'dart:typed_data';

import 'package:pdfrx/pdfrx.dart';

import '../db/app_database.dart';
import '../parsing/momo_statement_parser.dart';
import 'categorization_service.dart';

/// Extrait les caractères positionnés de toutes les pages d'un PDF.
/// Remplaçable dans les tests, pour ne pas dépendre de PDFium.
typedef StatementGlyphExtractor = Future<List<StatementGlyph>> Function(Uint8List pdf);

/// Le fichier choisi n'est pas un relevé MTN MoMo lisible.
class MomoStatementFormatException implements Exception {
  @override
  String toString() =>
      "Ce fichier ne ressemble pas à un relevé MTN MoMo : aucune transaction n'a pu y être lue.";
}

class MomoStatementImportSummary {
  const MomoStatementImportSummary({
    required this.lues,
    required this.importees,
    required this.debut,
    required this.fin,
    required this.incoherencesSolde,
  });

  /// Transactions lues dans le relevé.
  final int lues;

  /// Transactions nouvellement ajoutées ; les autres étaient déjà présentes
  /// (même identifiant de transaction MTN, via un SMS ou un import
  /// précédent).
  final int importees;
  final DateTime debut;
  final DateTime fin;

  /// Voir [MomoStatementParseResult.balanceBreaks] : non nul si des lignes
  /// ont pu être mal lues.
  final int incoherencesSolde;

  int get dejaPresentes => lues - importees;
}

/// Importe un relevé PDF exporté depuis l'app MTN MoMo : pour un compte
/// dont les SMS n'arrivent pas sur cet appareil (ex. un iPhone), c'est la
/// seule source des transactions. Chaque ligne suit le même chemin qu'un
/// SMS détecté (catégorisation, dé-duplication par identifiant de
/// transaction, mise en file de synchronisation) : réimporter un relevé, ou
/// un relevé qui chevauche le précédent, ne crée aucun doublon.
class MomoStatementImportService {
  MomoStatementImportService(
    this.db,
    this.categorization, {
    StatementGlyphExtractor? extractor,
  }) : _extractor = extractor ?? extrairePdf;

  final AppDatabase db;
  final CategorizationService categorization;
  final StatementGlyphExtractor _extractor;

  Future<MomoStatementImportSummary> importer(Uint8List pdf) async {
    final resultat = parseMomoStatement(await _extractor(pdf));
    if (resultat.rows.isEmpty) throw MomoStatementFormatException();

    var importees = 0;
    for (final row in resultat.rows) {
      final tx = momoStatementRowToTransaction(row);
      tx.categorie = await categorization.suggestCategory(tx);
      if (await db.insertTransactionIfNew(tx)) importees++;
    }
    final dates = resultat.rows.map((r) => r.date).toList()..sort();
    return MomoStatementImportSummary(
      lues: resultat.rows.length,
      importees: importees,
      debut: dates.first,
      fin: dates.last,
      incoherencesSolde: resultat.balanceBreaks,
    );
  }

  static Future<List<StatementGlyph>> extrairePdf(Uint8List pdf) async {
    await pdfrxFlutterInitialize();
    final doc = await PdfDocument.openData(pdf);
    try {
      final glyphs = <StatementGlyph>[];
      for (final page in doc.pages) {
        final texte = await page.loadText();
        if (texte == null) continue;
        for (var i = 0; i < texte.fullText.length; i++) {
          final r = texte.charRects[i];
          glyphs.add(StatementGlyph(
            page: page.pageNumber,
            char: texte.fullText[i],
            left: r.left,
            top: r.top,
            right: r.right,
            bottom: r.bottom,
          ));
        }
      }
      return glyphs;
    } finally {
      await doc.dispose();
    }
  }
}
