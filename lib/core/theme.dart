import 'package:flutter/material.dart';

/// Cunning Cat brand colours.
/// Indigo = trust, amber = savings (the cat's eye), emerald = verified savings,
/// coral = conditional offers and risk flags.
class BrandColors {
  static const indigo = Color(0xFF1E1B4B);
  static const indigoMid = Color(0xFF4338CA);
  static const violet = Color(0xFF7C3AED);
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFEF3C7);
  static const emerald = Color(0xFF059669);
  static const emeraldSoft = Color(0xFFD1FAE5);
  static const coral = Color(0xFFE11D48);
  static const coralSoft = Color(0xFFFFE4E6);
  static const slate = Color(0xFF64748B);
  static const canvas = Color(0xFFF5F4FB);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo, indigoMid, violet],
  );
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: BrandColors.indigoMid,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFFA5B4FC) : BrandColors.indigoMid,
    secondary: BrandColors.amber,
    error: BrandColors.coral,
    surface: dark ? const Color(0xFF16152B) : Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF0E0D1F) : BrandColors.canvas,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: dark ? const Color(0xFF0E0D1F) : BrandColors.canvas,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: scheme.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: BrandColors.amber.withValues(alpha: 0.25),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
