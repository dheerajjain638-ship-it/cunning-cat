import 'package:flutter/material.dart';

/// Cunning Cat brand colours.
/// Indigo = trust, amber = savings ("cat's eye"), emerald = verified savings,
/// coral = conditional offers and risk flags.
class BrandColors {
  static const indigo = Color(0xFF1E1B4B);
  static const amber = Color(0xFFF59E0B);
  static const emerald = Color(0xFF059669);
  static const coral = Color(0xFFE11D48);
  static const slate = Color(0xFF64748B);
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: BrandColors.indigo,
    brightness: brightness,
  ).copyWith(
    secondary: BrandColors.amber,
    error: BrandColors.coral,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
