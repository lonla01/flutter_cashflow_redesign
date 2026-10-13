import 'package:flutter/material.dart';

import '../services/auth_gate.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/gradient_button.dart';

/// Écran de connexion/inscription (email + mot de passe). Affiché tant que
/// l'utilisateur n'est pas authentifié (voir _RacineApp dans main.dart) ;
/// une fois connecté, la suite du flux (onboarding ou écran principal) ne
/// dépend plus que de la base locale, jamais du réseau.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _modeInscription = false;
  bool _enCours = false;
  String? _erreur;
  String? _emailConfirmationEnvoyeeA;
  bool _modeMotDePasseOublie = false;
  String? _emailRecuperationEnvoyeeA;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      if (_modeInscription) {
        final email = _emailController.text.trim();
        final sessionOuverte = await AuthGate.current.signUp(
          email: email,
          password: _passwordController.text,
        );
        if (!sessionOuverte && mounted) {
          setState(() => _emailConfirmationEnvoyeeA = email);
        }
      } else {
        await AuthGate.current.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _envoyerEmailRecuperation() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _erreur = 'Email invalide');
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await AuthGate.current.resetPasswordForEmail(email);
      if (!mounted) return;
      setState(() => _emailRecuperationEnvoyeeA = email);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_modeMotDePasseOublie) {
      return _ecranMotDePasseOublie();
    }
    if (_emailConfirmationEnvoyeeA != null) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Confirmez votre email'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.navy700),
              const SizedBox(height: 24),
              Text(
                'Un email de confirmation a été envoyé à '
                '$_emailConfirmationEnvoyeeA. Cliquez sur le lien qu\'il '
                'contient pour activer votre compte, puis connectez-vous.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),
              GradientButton(
                onPressed: () => setState(() {
                  _emailConfirmationEnvoyeeA = null;
                  _modeInscription = false;
                }),
                label: 'Retour à la connexion',
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _entete(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _modeInscription ? 'Créer un compte' : 'Content de vous revoir',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Connectez-vous pour synchroniser vos transactions entre vos '
                        'appareils. L\'app reste utilisable hors-ligne une fois connecté.',
                        style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Email invalide' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Au moins 6 caractères' : null,
                      ),
                      if (!_modeInscription)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _enCours
                                ? null
                                : () => setState(() {
                                      _modeMotDePasseOublie = true;
                                      _erreur = null;
                                    }),
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                      if (_erreur != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade100),
                          ),
                          child: Text(
                            _erreur!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      GradientButton(
                        onPressed: _enCours ? null : _valider,
                        loading: _enCours,
                        label: _modeInscription ? 'Créer le compte' : 'Se connecter',
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: _enCours
                            ? null
                            : () => setState(() => _modeInscription = !_modeInscription),
                        child: Text(
                          _modeInscription
                              ? 'Déjà un compte ? Se connecter'
                              : 'Pas de compte ? Créer un compte',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ecranMotDePasseOublie() {
    if (_emailRecuperationEnvoyeeA != null) {
      return Scaffold(
        appBar: const GradientAppBar(title: 'Vérifiez vos emails'),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.navy700),
              const SizedBox(height: 24),
              Text(
                'Un email de réinitialisation a été envoyé à '
                '$_emailRecuperationEnvoyeeA. Ouvrez-le sur cet appareil et '
                'suivez le lien pour choisir un nouveau mot de passe.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
              const SizedBox(height: 24),
              GradientButton(
                onPressed: () => setState(() {
                  _modeMotDePasseOublie = false;
                  _emailRecuperationEnvoyeeA = null;
                }),
                label: 'Retour à la connexion',
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: const GradientAppBar(title: 'Mot de passe oublié'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Entrez votre email : nous vous envoyons un lien pour choisir '
                'un nouveau mot de passe.',
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Text(
                    _erreur!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              GradientButton(
                onPressed: _enCours ? null : _envoyerEmailRecuperation,
                loading: _enCours,
                label: 'Envoyer le lien',
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _enCours
                    ? null
                    : () => setState(() {
                          _modeMotDePasseOublie = false;
                          _erreur = null;
                        }),
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entete() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cashflow',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
