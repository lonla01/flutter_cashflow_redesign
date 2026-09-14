import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// [FloatingActionButton] avec le dégradé navy de l'app, pour les actions
/// d'ajout (catégorie, etc.) plutôt que la couleur unie par défaut du
/// thème.
class GradientFab extends StatelessWidget {
  const GradientFab({super.key, required this.onPressed, this.icon = Icons.add, this.tooltip});

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x552A4C86), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip ?? '',
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
