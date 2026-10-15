import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_money_tracker/services/export_service.dart';

void main() {
  test('nomDeFichier garde lettres et chiffres, remplace le reste par "_"', () {
    expect(
      ExportService.nomDeFichier('transactions_S/S BOCOM TYO- VILLE_01/09/2026 – 15/10/2026'),
      'transactions_S_S_BOCOM_TYO_VILLE_01_09_2026_15_10_2026',
    );
    expect(ExportService.nomDeFichier('  Électricité (Octobre 2026) '), 'Électricité_Octobre_2026');
  });
}
