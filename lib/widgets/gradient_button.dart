import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bouton d'action principale avec le dégradé navy de l'app — utilisé pour
/// l'action la plus importante d'un écran (se connecter, enregistrer,
/// réessayer...), là où un [ElevatedButton] classique paraîtrait plat.
/// Les actions secondaires restent des [OutlinedButton]/[TextButton]
/// standards (stylés par le thème global) pour garder une hiérarchie
/// visuelle claire.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final actif = onPressed != null && !loading;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: actif ? AppGradients.primary : AppGradients.disabled,
          borderRadius: BorderRadius.circular(12),
          boxShadow: actif
              ? [
                  BoxShadow(
                    color: AppColors.navy700.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: actif ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                ] else if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
