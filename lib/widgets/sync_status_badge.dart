import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../services/sync_service.dart';

/// Indicateur discret d'état de synchronisation, affiché dans l'AppBar
/// partagée de l'app (voir _ShellPrincipal dans main.dart : HomeScreen et
/// DashboardScreen n'ont pas leur propre AppBar). Ne bloque jamais
/// l'usage de l'app — une simple icône avec tooltip.
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.syncService});

  final SyncService syncService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: AppDatabase.instance.watchPendingSyncCount(),
      builder: (context, countSnapshot) {
        final pending = countSnapshot.data ?? 0;
        return ValueListenableBuilder<SyncStatus>(
          valueListenable: syncService.status,
          builder: (context, status, _) {
            final (icon, color, message) = _presentation(status, pending);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Tooltip(
                message: message,
                child: Icon(icon, color: color, size: 22),
              ),
            );
          },
        );
      },
    );
  }

  (IconData, Color?, String) _presentation(SyncStatus status, int pending) {
    if (status == SyncStatus.erreur) {
      return (Icons.error_outline, Colors.redAccent, 'Erreur de synchronisation');
    }
    if (pending > 0) {
      return (
        Icons.cloud_off,
        Colors.grey,
        'En attente de connexion ($pending transaction${pending > 1 ? 's' : ''})',
      );
    }
    return (Icons.cloud_done, Colors.green, 'Synchronisé');
  }
}
