import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'db/app_database.dart';
import 'parsing/sms_listener.dart';
import 'screens/auth_screen.dart';
import 'screens/connection_status_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/recents_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/settings_screen.dart';
import 'services/auth_gate.dart';
import 'services/categorization_service.dart';
import 'services/sms_import_link_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';
import 'widgets/sync_status_badge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
  runApp(const CashflowApp());
}

class CashflowApp extends StatelessWidget {
  const CashflowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashflow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
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
  StreamSubscription<void>? _recoverySub;
  late final SyncService _syncService = SyncServiceFactory.builder(AppDatabase.instance);
  late final SmsImportLinkService _smsImportLinkService = SmsImportLinkService(
    AppDatabase.instance,
    CategorizationService(AppDatabase.instance),
  );

  @override
  void initState() {
    super.initState();
    _authSub = AuthGate.current.onAuthChanged.listen(_onAuthChanged);
    // Peut survenir à tout moment (app déjà ouverte ou lancée à froid via le
    // lien) et indépendamment de l'état d'authentification courant : ce même
    // événement fait aussi passer isAuthenticated à true via _onAuthChanged
    // (la session de récupération est une vraie session), donc les deux
    // écouteurs tournent en parallèle sans se marcher dessus.
    _recoverySub = AuthGate.current.onPasswordRecovery.listen((_) => _afficherRecuperation());
    // Démarré inconditionnellement (pas seulement si authentifié) : on veut
    // traiter un lien d'import reçu à froid dès que possible, et il ne fait
    // rien tant qu'aucun Raccourci ne lui envoie de lien `import-sms`.
    _smsImportLinkService.demarrer();
    if (_authentifie) {
      _syncService.start();
      _verifier();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _recoverySub?.cancel();
    _syncService.stop();
    _smsImportLinkService.arreter();
    super.dispose();
  }

  void _afficherRecuperation() {
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const ResetPasswordScreen(),
    ));
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
      _reprendreEcouteSmsSiAutorisee();
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e);
    }
  }

  /// Au premier lancement, l'écoute SMS en direct est démarrée depuis
  /// OnboardingScreen juste après l'octroi de la permission — mais ce
  /// démarrage ne survit pas au redémarrage du process. On la relance donc
  /// ici à chaque lancement, silencieusement et sans re-solliciter la
  /// permission : si elle n'a jamais été accordée (utilisateur en mode
  /// démo par exemple), on ne fait rien.
  bool _ecouteSmsDemarree = false;
  Future<void> _reprendreEcouteSmsSiAutorisee() async {
    if (_ecouteSmsDemarree || kIsWeb) return;
    if (!await Permission.sms.status.isGranted) return;
    _ecouteSmsDemarree = true;
    SmsListenerService(AppDatabase.instance, CategorizationService(AppDatabase.instance))
        .demarrerEcoute();
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

  static const _titres = ['Transactions', 'Récents', 'Rapports'];
  static const _ecrans = [HomeScreen(), RecentsScreen(), DashboardScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titres[_index]),
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.primary),
        ),
        actions: [
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ConnectionStatusScreen(syncService: widget.syncService),
            )),
            child: SyncStatusBadge(syncService: widget.syncService),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Réglages',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            )),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _ecrans),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Récents'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Rapports'),
        ],
      ),
    );
  }
}
