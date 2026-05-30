import 'package:flutter/material.dart';

class BrandPalette {
  const BrandPalette._();

  static const Color primary = Color(0xFF0E9F7A);
  static const Color primaryDark = Color(0xFF0A7A5D);
  static const Color secondary = Color(0xFFF4B63A);
  static const Color accent = Color(0xFF34D399);
  static const Color background = Color(0xFFF4FBF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F7F4);
  static const Color textPrimary = Color(0xFF12352B);
  static const Color textMuted = Color(0xFF5E736B);
}

class CrediMercTheme {
  const CrediMercTheme._();

  static ThemeData light() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: BrandPalette.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: BrandPalette.primary,
      onPrimary: Colors.white,
      secondary: BrandPalette.secondary,
      onSecondary: Colors.white,
      tertiary: BrandPalette.accent,
      surface: BrandPalette.surface,
      onSurface: BrandPalette.textPrimary,
      surfaceContainerHighest: BrandPalette.surfaceMuted,
      background: BrandPalette.background,
      onBackground: BrandPalette.textPrimary,
      error: const Color(0xFFB42318),
    );

    final textTheme = ThemeData.light().textTheme.apply(
          bodyColor: BrandPalette.textPrimary,
          displayColor: BrandPalette.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: BrandPalette.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: BrandPalette.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: BrandPalette.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BrandPalette.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandPalette.primaryDark,
          side: const BorderSide(color: Color(0xFFB7DDD0)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandPalette.secondary,
          foregroundColor: BrandPalette.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandPalette.surface,
        hintStyle: const TextStyle(color: BrandPalette.textMuted),
        labelStyle: const TextStyle(color: BrandPalette.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD8E7E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD8E7E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: BrandPalette.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB42318)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BrandPalette.surfaceMuted,
        selectedColor: BrandPalette.primary.withOpacity(0.14),
        labelStyle: const TextStyle(
          color: BrandPalette.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: const BorderSide(color: Color(0xFFD8E7E1)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: BrandPalette.secondary,
        foregroundColor: BrandPalette.textPrimary,
        elevation: 2,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFDDE9E4),
        space: 1,
        thickness: 1,
      ),
      textTheme: textTheme,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BrandPalette.primaryDark,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
