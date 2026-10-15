import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_money_tracker/db/app_database.dart';
import 'package:mobile_money_tracker/screens/custom_report_screen.dart';

import '../support/sample_transaction.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  setUp(() {
    AppDatabase.instance = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() => AppDatabase.instance.close());

  testWidgets('regroupement commutable et filtre par contacts', (tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      final db = AppDatabase.instance;
      for (final (contact, categorie, jour) in [
        ('Boutique', 'Alimentation', 2),
        ('Marché', 'Alimentation', 3),
        ('Station', 'Transport', 4),
      ]) {
        await db.insertTransactionIfNew(buildTransaction(
          contactNom: contact,
          categorie: categorie,
          dateTransaction: DateTime(2026, 9, jour),
        ));
      }
    });

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: CustomReportScreen(
        periodeInitiale: DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 9, 30)),
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('3 transactions'), findsOneWidget);
    expect(find.widgetWithText(ExpansionTile, 'Alimentation'), findsOneWidget);
    expect(find.widgetWithText(ExpansionTile, 'Boutique'), findsNothing);

    await tester.tap(find.text('Contact → Catégorie'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ExpansionTile, 'Boutique'), findsOneWidget);
    expect(find.widgetWithText(ExpansionTile, 'Alimentation'), findsNothing);

    await tester.tap(find.text('Tous les contacts'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Rechercher...'), 'sta');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'Boutique'), findsNothing);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Station'));
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    // Résumé du rapport + sous-titre de l'unique groupe.
    expect(find.text('1 transaction'), findsNWidgets(2));
    expect(find.widgetWithText(ExpansionTile, 'Station'), findsOneWidget);
    expect(find.widgetWithText(ExpansionTile, 'Boutique'), findsNothing);
  });
}
