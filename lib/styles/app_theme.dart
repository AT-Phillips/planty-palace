import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A selectable app background "flavour" - the surface/card/input tones the
/// whole app sits on, chosen independently of the accent (seed) color. The
/// accent still drives primary/secondary; these just re-tint the backdrop.
class BackgroundPalette {
  final String name;

  // Dark theme: deliberately large, unambiguous contrast steps between
  // background (darkest) < card < input fill (lightest), because Material 3's
  // auto-generated dark tiers land too close together to read as layers.
  final Color darkBackground;
  final Color darkCard;
  final Color darkInputFill;

  // Light theme: a distinctly tinted (but still light) surface, with cards a
  // near-white lift above it. These are perceptibly different per palette so
  // switching actually re-tints the app in light mode - not four near-white
  // off-whites that all look the same.
  final Color lightBackground;
  final Color lightCard;

  const BackgroundPalette({
    required this.name,
    required this.darkBackground,
    required this.darkCard,
    required this.darkInputFill,
    required this.lightBackground,
    required this.lightCard,
  });

  /// The swatch to preview in the Settings picker for the given brightness -
  /// so the dot shows what the user will actually get.
  Color swatchFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkBackground : lightBackground;
}

class AppTheme {
  static const Color defaultSeedColor = Color(
    0xFF2E6B4F,
  ); // deep, considered sage green
  static const double radius = 20.0;

  /// The brighter "live / interactive" accent - a fresh fern green used for
  /// primary actions, active states, and healthy-care signals. Distinct from
  /// the deeper brand [defaultSeedColor] sage (which still drives the overall
  /// [ColorScheme]); this is the punchier green reserved for things the user
  /// acts on. Dark mode lifts it so it stays luminous on a dark ground.
  static Color fernColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF45C486)
          : const Color(0xFF1F9D63);

  /// Overdue-care urgency - deliberately distinct from both
  /// [ColorScheme.error] (destructive actions, form validation) and the
  /// amber toxicity-warning color, so all three read as separate signals
  /// instead of competing for the same "pay attention" red. This is the one
  /// coral used everywhere overdue care is signaled (Care rows, the Spaces
  /// to-do banner, plant-detail care rings).
  static Color urgentColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFE8825F)
          : const Color(0xFFDB5F38);

  /// Care-urgency ring/badge colors, keyed to how soon a schedule is due:
  /// healthy (plenty of time) -> [fernColor], approaching -> amber,
  /// overdue -> [urgentColor]. Centralized so the Care list, plant-detail
  /// care rings, and any status badge all read from one source.
  static Color careHealthy(BuildContext context) => fernColor(context);

  static Color careSoon(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFD6AC5A)
          : const Color(0xFFC9962B);

  static Color careOverdue(BuildContext context) => urgentColor(context);

  /// The serif heading style used for plant/species name headings (not app
  /// bar titles, which pick up the same Lora serif automatically via
  /// [ThemeData.appBarTheme] - this is for name headings living inside
  /// regular screen content, e.g. a plant card title or the detail screen's
  /// hero name).
  static TextStyle plantNameStyle(BuildContext context, {double size = 20}) {
    return GoogleFonts.lora(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  /// The current default - the original hand-tuned green-tinted dark theme
  /// with a soft sage light surface.
  static const BackgroundPalette forestPalette = BackgroundPalette(
    name: 'Forest',
    darkBackground: Color(0xFF0B120E),
    darkCard: Color(0xFF1C2A22),
    darkInputFill: Color(0xFF2A3931),
    lightBackground: Color(0xFFC7D4C2),
    lightCard: Color(0xFFF3F7F0),
  );

  /// All selectable background palettes, in picker order. `forestPalette` is
  /// index 0 (the default).
  static const List<BackgroundPalette> backgroundPalettes = [
    forestPalette,
    BackgroundPalette(
      name: 'Midnight',
      darkBackground: Color(0xFF0B1220),
      darkCard: Color(0xFF1B2537),
      darkInputFill: Color(0xFF29354B),
      lightBackground: Color(0xFFC3D2E8),
      lightCard: Color(0xFFF1F5FB),
    ),
    BackgroundPalette(
      name: 'Slate',
      darkBackground: Color(0xFF12151A),
      darkCard: Color(0xFF232830),
      darkInputFill: Color(0xFF333A44),
      lightBackground: Color(0xFFCBCFD6),
      lightCard: Color(0xFFF3F4F6),
    ),
    BackgroundPalette(
      name: 'Charcoal',
      darkBackground: Color(0xFF0E0F11),
      darkCard: Color(0xFF1E2023),
      darkInputFill: Color(0xFF2C2F33),
      lightBackground: Color(0xFFD9D2C5),
      lightCard: Color(0xFFF8F5EF),
    ),
  ];

  static ThemeData lightTheme({
    Color seedColor = defaultSeedColor,
    BackgroundPalette palette = forestPalette,
  }) => _themeFor(Brightness.light, seedColor, palette);

  static ThemeData darkTheme({
    Color seedColor = defaultSeedColor,
    BackgroundPalette palette = forestPalette,
  }) => _themeFor(Brightness.dark, seedColor, palette);

  static ThemeData _themeFor(
    Brightness brightness,
    Color seedColor,
    BackgroundPalette palette,
  ) {
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
    final baseTextTheme =
        brightness == Brightness.dark
            ? GoogleFonts.interTextTheme(
              ThemeData(brightness: Brightness.dark).textTheme,
            )
            : GoogleFonts.interTextTheme();

    final cardColor =
        brightness == Brightness.dark ? palette.darkCard : palette.lightCard;

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
        // Serif display type for every screen title - the one editorial
        // touch that's shared infrastructure (FrostedAppBar), so every
        // screen picks it up without a per-screen change.
        titleTextStyle: GoogleFonts.lora(
          fontSize: 21,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
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
        shape: StadiumBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      // Soften the default near-square popup menus (e.g. the Spaces/Care
      // "more" menus) into rounded, accent-tinted surfaces that stand out
      // from the tile they came from, rather than blending into it.
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.primaryContainer,
        elevation: 3,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: colorScheme.onPrimaryContainer),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.primaryContainer),
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
