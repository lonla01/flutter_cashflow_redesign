import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'db/app_database.dart';
import 'screens/auth_screen.dart';
import 'screens/connection_status_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_gate.dart';
import 'services/sync_service.dart';
import 'widgets/sync_status_badge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
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

/// Racine de l'app : gère dans l'ordre (1) l'authentification — la seule
/// étape qui exige une connexion, au tout premier lancement — puis (2) la
/// présence de données locales, exactement comme en Phase 1. Une fois
/// authentifié, tout le reste ne dépend plus que de la base locale : la
/// session Supabase est restaurée depuis le stockage local par
/// `Supabase.initialize()`, donc `AuthGate.current.isAuthenticated` ne
/// nécessite aucun appel réseau.
class _RacineApp extends StatefulWidget {
  const _RacineApp();

  @override
  State<_RacineApp> createState() => _RacineAppState();
}

class _RacineAppState extends State<_RacineApp> {
  late bool _authentifie = AuthGate.current.isAuthenticated;
  bool? _aDesDonnees;
  Object? _erreur;
  StreamSubscription<bool>? _authSub;
  late final SyncService _syncService = SyncServiceFactory.builder(AppDatabase.instance);

  @override
  void initState() {
    super.initState();
    _authSub = AuthGate.current.onAuthChanged.listen(_onAuthChanged);
    if (_authentifie) {
      _syncService.start();
      _verifier();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _syncService.stop();
    super.dispose();
  }

  void _onAuthChanged(bool authentifie) {
    if (!mounted) return;
    setState(() {
      _authentifie = authentifie;
      if (!authentifie) _aDesDonnees = null;
    });
    if (authentifie) {
      _syncService.start();
      _verifier();
    } else {
      _syncService.stop();
    }
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
    if (!_authentifie) {
      return const AuthScreen();
    }
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
    return _ShellPrincipal(syncService: _syncService);
  }
}

class _ShellPrincipal extends StatefulWidget {
  const _ShellPrincipal({required this.syncService});

  final SyncService syncService;

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
      appBar: AppBar(
        title: Text(_titres[_index]),
        actions: [
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ConnectionStatusScreen(syncService: widget.syncService),
            )),
            child: SyncStatusBadge(syncService: widget.syncService),
          ),
        ],
      ),
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
