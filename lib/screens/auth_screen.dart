import 'package:flutter/material.dart';

import '../services/auth_gate.dart';

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
        await AuthGate.current.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_modeInscription ? 'Créer un compte' : 'Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Suivi Mobile Money',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous pour synchroniser vos transactions entre vos appareils. '
                'L\'app reste utilisable hors-ligne une fois connecté.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Email invalide' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Au moins 6 caractères' : null,
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 12),
                Text(_erreur!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _enCours ? null : _valider,
                child: _enCours
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_modeInscription ? 'Créer le compte' : 'Se connecter'),
              ),
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
    );
  }
}
