import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_tracker/services/receipt_extraction_service.dart';

void main() {
  group('ReceiptExtractedFields.fromMap', () {
    test('parse un montant entier ou décimal (num JSON)', () {
      final champs = ReceiptExtractedFields.fromMap({
        'montant': 12500,
        'marchand': 'Boutique X',
        'date': '2026-09-10',
        'notes': 'Courses',
      });

      expect(champs.montant, 12500.0);
      expect(champs.marchand, 'Boutique X');
      expect(champs.date, DateTime(2026, 9, 10));
      expect(champs.notes, 'Courses');
      expect(champs.estVide, isFalse);
    });

    test('champs absents/null restent null sans lever d\'erreur', () {
      final champs = ReceiptExtractedFields.fromMap({
        'montant': null,
        'marchand': null,
        'date': null,
        'notes': null,
      });

      expect(champs.montant, isNull);
      expect(champs.marchand, isNull);
      expect(champs.date, isNull);
      expect(champs.notes, isNull);
      expect(champs.estVide, isTrue);
    });

    test('une date illisible devient null plutôt que de lever', () {
      final champs = ReceiptExtractedFields.fromMap({'date': 'pas une date'});
      expect(champs.date, isNull);
    });
  });
}
