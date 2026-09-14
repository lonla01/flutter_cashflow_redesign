import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// AppBar avec le dégradé navy de l'app, à utiliser sur tout écran ayant
/// sa propre app bar (les écrans affichés dans l'IndexedStack de
/// _ShellPrincipal dans main.dart partagent déjà son app bar dégradée et
/// n'en ont pas besoin).
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.primary),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
