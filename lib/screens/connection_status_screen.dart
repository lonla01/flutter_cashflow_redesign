import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../db/app_database.dart';
import '../services/sync_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/gradient_button.dart';

/// Écran d'état de la connexion au backend Supabase : projet configuré,
/// compte connecté, statut de synchronisation détaillé et action de
/// réessai manuel. Le projet Supabase est fixe (configuré au build, voir
/// [SupabaseConfig]) : cet écran diagnostique l'état de la connexion, il
/// ne permet pas de changer de projet.
class ConnectionStatusScreen extends StatelessWidget {
  const ConnectionStatusScreen({super.key, required this.syncService});

  final SyncService syncService;

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Connexion'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(context, 'Backend', [
            _ligne('Projet Supabase', SupabaseConfig.url),
            _ligne('Compte', email ?? 'Non connecté'),
          ]),
          const SizedBox(height: 24),
          _section(context, 'Synchronisation', [
            ValueListenableBuilder<SyncStatus>(
              valueListenable: syncService.status,
              builder: (context, status, _) {
                return StreamBuilder<int>(
                  stream: AppDatabase.instance.watchPendingSyncCount(),
                  builder: (context, snapshot) {
                    final pending = snapshot.data ?? 0;
                    final (icon, color, label) = _statusPresentation(status, pending);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(icon, color: color),
                          title: Text(label),
                          subtitle: pending > 0
                              ? Text('$pending transaction${pending > 1 ? 's' : ''} en attente')
                              : null,
                        ),
                        if (status == SyncStatus.erreur)
                          FutureBuilder<String?>(
                            future: AppDatabase.instance.getLastSyncError(),
                            builder: (context, errSnapshot) {
                              final message = errSnapshot.data;
                              if (message == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                                child: Text(
                                  message,
                                  style: TextStyle(color: Colors.redAccent.shade200, fontSize: 12),
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ]),
          const SizedBox(height: 24),
          GradientButton(
            onPressed: syncService.retryNow,
            icon: Icons.refresh,
            label: 'Réessayer maintenant',
          ),
        ],
      ),
    );
  }

  (IconData, Color?, String) _statusPresentation(SyncStatus status, int pending) {
    if (status == SyncStatus.erreur) {
      return (Icons.error_outline, Colors.redAccent, 'Erreur de synchronisation');
    }
    if (pending > 0) {
      return (Icons.cloud_off, Colors.grey, 'En attente de connexion');
    }
    return (Icons.cloud_done, Colors.green, 'Synchronisé');
  }

  Widget _section(BuildContext context, String titre, List<Widget> enfants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: enfants),
          ),
        ),
      ],
    );
  }

  // Colonne (label au-dessus, valeur en dessous) plutôt qu'une ligne
  // label/valeur côte à côte : une valeur sans espaces (une URL) ne peut
  // pas passer à la ligne au milieu d'un "mot", donc une disposition en
  // ligne déborde. En colonne, toute la largeur de la carte est
  // disponible, et l'ellipse reste un filet de sécurité pour une valeur
  // vraiment trop longue.
  Widget _ligne(String label, String valeur) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            const SizedBox(height: 3),
            Text(
              valeur,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}
