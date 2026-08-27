import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'db/app_database.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  await initializeDateFormatting('fr_FR', null);
  runApp(const MobileMoneyTrackerApp());
}

class MobileMoneyTrackerApp extends StatelessWidget {
  const MobileMoneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suivi Mobile Money',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const _RacineApp(),
    );
  }
}

class _RacineApp extends StatefulWidget {
  const _RacineApp();

  @override
  State<_RacineApp> createState() => _RacineAppState();
}

class _RacineAppState extends State<_RacineApp> {
  bool? _aDesDonnees;
  Object? _erreur;

  @override
  void initState() {
    super.initState();
    _verifier();
  }

  Future<void> _verifier() async {
    try {
      final count = await AppDatabase.instance.countTransactions();
      if (!mounted) return;
      setState(() => _aDesDonnees = count > 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_erreur != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur de démarrage')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText('Impossible d\'ouvrir la base locale :\n\n$_erreur'),
        ),
      );
    }
    if (_aDesDonnees == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_aDesDonnees == false) {
      return OnboardingScreen(onTermine: () => setState(() => _aDesDonnees = true));
    }
    return const _ShellPrincipal();
  }
}

class _ShellPrincipal extends StatefulWidget {
  const _ShellPrincipal();

  @override
  State<_ShellPrincipal> createState() => _ShellPrincipalState();
}

class _ShellPrincipalState extends State<_ShellPrincipal> {
  int _index = 0;

  static const _titres = ['Transactions', 'Rapports'];
  static const _ecrans = [HomeScreen(), DashboardScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titres[_index])),
      body: IndexedStack(index: _index, children: _ecrans),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Rapports'),
        ],
      ),
    );
  }
}
