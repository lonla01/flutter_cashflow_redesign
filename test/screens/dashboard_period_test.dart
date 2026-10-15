// Période libre du tableau de bord : toucher l'en-tête du mois ouvre un
// sélecteur de dates, la période choisie filtre le rapport, et la puce
// "Période personnalisée" ramène à la vue mensuelle.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mobile_money_tracker/db/app_database.dart';
import 'package:mobile_money_tracker/screens/dashboard_screen.dart';

import '../support/sample_transaction.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  setUp(() {
    AppDatabase.instance = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() => AppDatabase.instance.close());

  testWidgets('une période choisie couvre plusieurs mois, la puce revient au mois',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final moisPrecedent = DateTime(now.year, now.month - 1, 10);
    await tester.runAsync(() async {
      await AppDatabase.instance.insertTransactionIfNew(
          buildTransaction(contactNom: 'Shop Courant', dateTransaction: DateTime(now.year, now.month, 1)));
      await AppDatabase.instance.insertTransactionIfNew(
          buildTransaction(contactNom: 'Shop Précédent', dateTransaction: moisPrecedent));
    });

    await tester.pumpWidget(const MaterialApp(
      locale: Locale('fr', 'FR'),
      supportedLocales: [Locale('fr', 'FR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: DashboardScreen()),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('Shop Courant'), findsOneWidget);
    expect(find.text('Shop Précédent'), findsNothing);

    await tester.tap(find.byIcon(Icons.date_range));
    await tester.pumpAndSettle();
    expect(find.text('Choisir une période'), findsOneWidget);

    // Saisie au clavier plutôt qu'au calendrier.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    final jour = DateFormat('dd/MM/yyyy', 'fr_FR');
    final champs = find.byType(TextField);
    await tester.enterText(champs.at(0), jour.format(DateTime(now.year, now.month - 1, 1)));
    await tester.enterText(champs.at(1), jour.format(DateTime(now.year, now.month, 1)));
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    expect(find.text('Shop Courant'), findsOneWidget);
    expect(find.text('Shop Précédent'), findsOneWidget);
    expect(
      find.text('${jour.format(DateTime(now.year, now.month - 1, 1))} – '
          '${jour.format(DateTime(now.year, now.month, 1))}'),
      findsOneWidget,
    );

    await tester.tap(find.descendant(
      of: find.widgetWithText(InputChip, 'Période personnalisée'),
      matching: find.byType(Icon),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Période personnalisée'), findsNothing);
    expect(find.text('Shop Précédent'), findsNothing);
  });
}
