import 'package:flutter/material.dart';

class AppColors {
  static const emerald = Color(0xFF1B7A4D);
  static const emeraldSoftLight = Color(0xFFE6F2EA);
  static const coral = Color(0xFFD6491F);
  static const coralSoftLight = Color(0xFFFBEAE3);
  static const azure = Color(0xFF2F6FED);
  static const azureSoftLight = Color(0xFFE9EFFD);
  static const amber = Color(0xFFC4801A);
  static const amberSoftLight = Color(0xFFFBF0DD);
  static const violet = Color(0xFF6E4FB0);
  static const violetSoftLight = Color(0xFFEFE9F8);

  static const paperLight = Color(0xFFF7F5F0);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surface2Light = Color(0xFFEFEBE2);
  static const lineLight = Color(0xFFE4DFD3);
  static const inkLight = Color(0xFF16211C);
  static const inkSoftLight = Color(0xFF4B564F);
  static const inkFaintLight = Color(0xFF8A9389);

  static const paperDark = Color(0xFF0F1512);
  static const surfaceDark = Color(0xFF172019);
  static const surface2Dark = Color(0xFF1E2921);
  static const lineDark = Color(0xFF28352C);
  static const inkDark = Color(0xFFEDEFE9);
  static const inkSoftDark = Color(0xFFAEB6A9);
  static const inkFaintDark = Color(0xFF6C766A);
}

ThemeData buildLightTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.emerald,
    brightness: Brightness.light,
  );
  final scheme = base.copyWith(
    primary: AppColors.emerald,
    secondary: AppColors.azure,
    error: AppColors.coral,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.inkLight,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paperLight,
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.lineLight),
      ),
    ),
    dividerColor: AppColors.lineLight,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.inkLight),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paperLight,
      foregroundColor: AppColors.inkLight,
      elevation: 0,
    ),
  );
}

ThemeData buildDarkTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.emerald,
    brightness: Brightness.dark,
  );
  final scheme = base.copyWith(
    primary: const Color(0xFF3FA972),
    secondary: const Color(0xFF6C93F5),
    error: const Color(0xFFE8724A),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.inkDark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paperDark,
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.lineDark),
      ),
    ),
    dividerColor: AppColors.lineDark,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.inkDark),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paperDark,
      foregroundColor: AppColors.inkDark,
      elevation: 0,
    ),
  );
}

// Convenience extension so widgets can pick the right "soft"/faint tone
// depending on the current brightness without repeating logic everywhere.
extension BuildContextKasku on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get inkFaint =>
      isDark ? AppColors.inkFaintDark : AppColors.inkFaintLight;
  Color get inkSoft => isDark ? AppColors.inkSoftDark : AppColors.inkSoftLight;
  Color get lineColor => isDark ? AppColors.lineDark : AppColors.lineLight;
  Color get surface2 => isDark ? AppColors.surface2Dark : AppColors.surface2Light;
}
