import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_tracker/models/transaction.dart';

void main() {
  group('TransactionSource', () {
    test('sourceToString/sourceFromString round-trip pour chaque valeur', () {
      for (final source in TransactionSource.values) {
        expect(sourceFromString(sourceToString(source)), source);
      }
    });

    test('manuel sérialise vers "manuel"', () {
      expect(sourceToString(TransactionSource.manuel), 'manuel');
      expect(sourceFromString('manuel'), TransactionSource.manuel);
    });

    test('sourceFromString lève pour une valeur inconnue', () {
      expect(() => sourceFromString('bitcoin'), throwsArgumentError);
    });

    test('sourceLabel donne un libellé distinct par source', () {
      final libelles = TransactionSource.values.map(sourceLabel).toSet();
      expect(libelles, hasLength(TransactionSource.values.length));
      expect(sourceLabel(TransactionSource.manuel), 'Saisie manuelle');
    });
  });
}
