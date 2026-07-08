import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A selectable app background "flavour" - the surface/card/input tones the
/// whole app sits on, chosen independently of the accent (seed) color. The
/// accent still drives primary/secondary; these just re-tint the backdrop.
class BackgroundPalette {
  final String name;

  /// A representative swatch shown in the Settings picker (the dark
  /// background, which is where these palettes differ most visibly).
  final Color swatch;

  // Dark theme: deliberately large, unambiguous contrast steps between
  // background (darkest) < card < input fill (lightest), because Material 3's
  // auto-generated dark tiers land too close together to read as layers.
  final Color darkBackground;
  final Color darkCard;
  final Color darkInputFill;

  // Light theme: a subtle off-white so the light theme isn't stark/clinical.
  final Color lightBackground;

  const BackgroundPalette({
    required this.name,
    required this.swatch,
    required this.darkBackground,
    required this.darkCard,
    required this.darkInputFill,
    required this.lightBackground,
  });
}

class AppTheme {
  static const Color defaultSeedColor = Color(0xFF2E6B4F); // deep, considered sage green
  static const double radius = 20.0;

  /// The current default - the original hand-tuned green-tinted dark theme
  /// and warm off-white light background.
  static const BackgroundPalette forestPalette = BackgroundPalette(
    name: 'Forest',
    swatch: Color(0xFF0B120E),
    darkBackground: Color(0xFF0B120E),
    darkCard: Color(0xFF1C2A22),
    darkInputFill: Color(0xFF2A3931),
    lightBackground: Color(0xFFF6F7F2),
  );

  /// All selectable background palettes, in picker order. `forestPalette` is
  /// index 0 (the default).
  static const List<BackgroundPalette> backgroundPalettes = [
    forestPalette,
    BackgroundPalette(
      name: 'Midnight',
      swatch: Color(0xFF0B1220),
      darkBackground: Color(0xFF0B1220),
      darkCard: Color(0xFF1B2537),
      darkInputFill: Color(0xFF29354B),
      lightBackground: Color(0xFFF1F4FA),
    ),
    BackgroundPalette(
      name: 'Slate',
      swatch: Color(0xFF12151A),
      darkBackground: Color(0xFF12151A),
      darkCard: Color(0xFF232830),
      darkInputFill: Color(0xFF333A44),
      lightBackground: Color(0xFFF3F4F6),
    ),
    BackgroundPalette(
      name: 'Charcoal',
      swatch: Color(0xFF0E0F11),
      darkBackground: Color(0xFF0E0F11),
      darkCard: Color(0xFF1E2023),
      darkInputFill: Color(0xFF2C2F33),
      lightBackground: Color(0xFFF5F5F4),
    ),
  ];

  static ThemeData lightTheme({
    Color seedColor = defaultSeedColor,
    BackgroundPalette palette = forestPalette,
  }) =>
      _themeFor(Brightness.light, seedColor, palette);

  static ThemeData darkTheme({
    Color seedColor = defaultSeedColor,
    BackgroundPalette palette = forestPalette,
  }) =>
      _themeFor(Brightness.dark, seedColor, palette);

  static ThemeData _themeFor(Brightness brightness, Color seedColor, BackgroundPalette palette) {
    var colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) {
      colorScheme = colorScheme.copyWith(
        surface: palette.darkBackground,
        surfaceContainerHighest: palette.darkInputFill,
      );
    } else {
      colorScheme = colorScheme.copyWith(surface: palette.lightBackground);
    }
    final baseTextTheme = brightness == Brightness.dark
        ? GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme)
        : GoogleFonts.interTextTheme();

    final cardColor =
        brightness == Brightness.dark ? palette.darkCard : colorScheme.surfaceContainerHigh;

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
      // Soften the default near-square popup menus (e.g. the Spaces/Care
      // "more" menus) into rounded, card-toned surfaces consistent with the
      // rest of the app.
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        elevation: 3,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(cardColor),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
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
