import 'package:flutter/material.dart';

/// Palette navy unifiée de l'app. Toute couleur "structurelle" (app bar,
/// boutons, sélection, focus) doit venir d'ici plutôt que d'un
/// `Colors.xxx` codé en dur dans un écran, pour que le thème reste
/// cohérent partout sans avoir à auditer chaque fichier séparément.
class AppColors {
  AppColors._();

  static const navy900 = Color(0xFF071A3D); // le plus sombre : app bar, hero
  static const navy800 = Color(0xFF0D2B63);
  static const navy700 = Color(0xFF15417F); // couleur "primary" de l'app
  static const navy600 = Color(0xFF1F55A6);
  static const navy500 = Color(0xFF3572C4); // le plus clair : extrémité de dégradé
  static const surface = Color(0xFFF4F6FB); // fond général, légèrement bleuté
}

/// Dégradés réutilisables pour l'aspect "premium" demandé : app bar,
/// boutons principaux, en-têtes héros (connexion/onboarding), badges
/// d'avatar. Toujours navy -> navy plus clair, jamais une couleur hors
/// palette, pour rester cohérent d'un écran à l'autre.
class AppGradients {
  AppGradients._();

  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.navy900, AppColors.navy700, AppColors.navy500],
  );

  static const vertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.navy800, AppColors.navy600],
  );

  /// Version grisée du dégradé principal, pour un [GradientButton]
  /// désactivé — garde la même forme visuelle plutôt que de basculer sur
  /// un style totalement différent.
  static const disabled = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB0B6C2), Color(0xFF9AA1AF)],
  );
}

/// Palette pour la répartition par catégorie (graphique + légende du
/// rapport mensuel). Distincte de la palette navy structurelle : un
/// camembert tout en nuances de bleu serait illisible, donc on utilise
/// des teintes "joyaux" qui restent harmonieuses avec le navy dominant du
/// reste de l'app plutôt que les couleurs Material par défaut.
const List<Color> categoryChartColors = [
  Color(0xFF3572C4), // bleu (cohérent avec le navy)
  Color(0xFFC9A227), // or
  Color(0xFF2E8B74), // émeraude
  Color(0xFFB0413E), // rouge brique
  Color(0xFF6B4FA0), // violet
  Color(0xFFD97A3E), // ambre
  Color(0xFF3E7CB1), // bleu ciel
  Color(0xFF8C5B3E), // brun
  Color(0xFFB0568C), // magenta doux
  Color(0xFF5C8A3E), // vert olive
];

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.navy700,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.navy700,
    onPrimary: Colors.white,
    secondary: AppColors.navy500,
    surface: Colors.white,
  );

  final baseBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey.shade300),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    splashFactory: InkRipple.splashFactory,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy900,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 3,
      indicatorColor: AppColors.navy700.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.navy800 : Colors.grey.shade600,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? AppColors.navy800 : Colors.grey.shade500);
      }),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.navy600, width: 2),
      ),
      errorBorder: baseBorder.copyWith(
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: Colors.grey.shade700),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy700,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy700,
        side: const BorderSide(color: AppColors.navy700, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.navy700,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppColors.navy700,
      disabledColor: Colors.grey.shade100,
      labelStyle: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.navy900),
      shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300)),
      side: BorderSide.none,
      showCheckmark: false,
    ),

    dividerTheme: DividerThemeData(color: Colors.grey.shade200, space: 1),

    listTileTheme: const ListTileThemeData(iconColor: AppColors.navy700),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.navy700,
      foregroundColor: Colors.white,
      elevation: 2,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.navy900,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),

    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.1),
      titleLarge: TextStyle(fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(height: 1.35),
    ).apply(bodyColor: AppColors.navy900, displayColor: AppColors.navy900),
  );
}
