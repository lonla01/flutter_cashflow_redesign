import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models/transaction.dart';

/// Rend [child] supprimable d'un glissement vers la gauche. [onDismissed]
/// doit retirer la transaction de la liste affichée de façon synchrone
/// (exigence de [Dismissible]), puis appeler [supprimerAvecAnnulation].
class SwipeToDelete extends StatelessWidget {
  const SwipeToDelete({
    super.key,
    required this.transaction,
    required this.onDismissed,
    required this.child,
    this.enabled = true,
  });

  final MoneyTransaction transaction;
  final VoidCallback onDismissed;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('swipe-${transaction.id}'),
      direction: enabled ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Supprimer',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white),
          ],
        ),
      ),
      child: child,
    );
  }
}

/// Supprime [tx] (suppression synchronisée vers les autres appareils) et
/// propose de l'annuler pendant quelques secondes. [onRestored] est appelé
/// après une annulation, pour que l'écran réaffiche la transaction.
Future<void> supprimerAvecAnnulation(
  BuildContext context,
  MoneyTransaction tx, {
  required VoidCallback onRestored,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  await AppDatabase.instance.deleteTransaction(tx.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content:
          Text('Transaction "${tx.contactNom ?? 'Contact inconnu'}" supprimée'),
      action: SnackBarAction(
        label: 'Annuler',
        onPressed: () async {
          await AppDatabase.instance.restoreTransaction(tx);
          onRestored();
        },
      ),
    ));
}
