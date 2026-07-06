import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color defaultSeedColor = Color(0xFF2E6B4F); // deep, considered sage green
  static const double radius = 20.0;

  static ThemeData lightTheme({Color seedColor = defaultSeedColor}) =>
      _themeFor(Brightness.light, seedColor);
  static ThemeData darkTheme({Color seedColor = defaultSeedColor}) =>
      _themeFor(Brightness.dark, seedColor);

  // Material 3's auto-generated dark tonal palette keeps surface and its
  // "container" tiers too close together to read as distinct layers (a
  // ~9% white blend tried previously turned out to land almost exactly on
  // the original tone - not actually much of a fix). These are explicit,
  // fixed values with deliberately large, unambiguous contrast steps:
  // background (darkest) < card < input fill (lightest).
  static const _darkBackground = Color(0xFF0B120E);
  static const _darkCard = Color(0xFF1C2A22);
  static const _darkInputFill = Color(0xFF2A3931);

  // Material 3's light seed-generated surface lands essentially at pure
  // white, which reads as stark/clinical for a plant-care app. A subtle
  // warm off-white keeps the light theme soft without darkening it enough
  // to look muddy.
  static const _lightBackground = Color(0xFFF6F7F2);

  static ThemeData _themeFor(Brightness brightness, Color seedColor) {
    var colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) {
      colorScheme = colorScheme.copyWith(
        surface: _darkBackground,
        surfaceContainerHighest: _darkInputFill,
      );
    } else {
      colorScheme = colorScheme.copyWith(surface: _lightBackground);
    }
    final baseTextTheme = brightness == Brightness.dark
        ? GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme)
        : GoogleFonts.interTextTheme();

    final cardColor = brightness == Brightness.dark ? _darkCard : colorScheme.surfaceContainerHigh;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimary),
        shape: StadiumBorder(side: BorderSide(color: colorScheme.outlineVariant)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHighest,
          selectedBackgroundColor: colorScheme.primary,
          selectedForegroundColor: colorScheme.onPrimary,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: const CircleBorder(),
      ),
    );
  }
}
