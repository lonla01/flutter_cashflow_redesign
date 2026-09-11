// Smoke test verifying the app boots without a fatal error.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_money_tracker/main.dart';

void main() {
  testWidgets('App démarre sans erreur et affiche le chargement initial', (WidgetTester tester) async {
    await tester.pumpWidget(const MobileMoneyTrackerApp());

    // Le premier frame affiche un indicateur de chargement pendant la vérification de la base.
    // (CircularProgressIndicator anime indéfiniment, donc on ne peut pas pumpAndSettle ici ;
    // la suite dépend du plugin sqflite, indisponible dans un simple widget test.)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
