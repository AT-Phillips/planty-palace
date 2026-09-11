import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

export 'palette.dart' show Palette, PaletteContext;

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

  // -------------------------------------------------------------------
  // Color accessors. These now delegate to [Palette] - the single literal
  // source of truth - rather than each redefining its own hexes. Kept as
  // named helpers because they read well at call sites and describe intent
  // ("careOverdue") rather than appearance ("coral").
  // -------------------------------------------------------------------

  /// The live/interactive accent: primary actions and active states.
  static Color fernColor(BuildContext context) => context.palette.fern;

  /// Overdue care. Distinct from [ColorScheme.error] (destructive actions)
  /// and from the amber toxicity warning, so all three read as separate
  /// signals instead of competing for one "alert" red.
  static Color urgentColor(BuildContext context) => context.palette.coral;

  /// Care-urgency colors, keyed to how soon a schedule is due:
  /// healthy -> fern, approaching -> amber, overdue -> coral.
  static Color careHealthy(BuildContext context) => context.palette.mintRing;

  static Color careSoon(BuildContext context) => context.palette.amber;

  static Color careOverdue(BuildContext context) => context.palette.coral;

  /// The uppercase, letter-spaced, muted label that opens a section
  /// ("CARE", "GROWTH PHOTOS"). Replaces the accent-colored sentence-case
  /// headings that made every screen read as stock Material.
  static TextStyle sectionLabelStyle(BuildContext context) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
    color: context.palette.inkFaint,
  );

  /// Small uppercase caption used inside tiles (a care tile's "WATER").
  static TextStyle microLabelStyle(BuildContext context) => TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: context.palette.inkFaint,
  );

  /// Italic secondary line under a plant name (its species).
  static TextStyle speciesStyle(BuildContext context, {double size = 12}) =>
      TextStyle(
        fontSize: size,
        fontStyle: FontStyle.italic,
        color: context.palette.inkSoft,
      );

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

  /// All selectable background palettes, in picker order (index 0 = Forest,
  /// the default). Derived from [Palette.variants] so the Settings swatches
  /// always preview the exact tones the app will actually render - there is
  /// only ever one source of truth for a palette's colors.
  static final List<BackgroundPalette> backgroundPalettes = [
    for (final (name, index) in const [
      ('Forest', 0),
      ('Midnight', 1),
      ('Slate', 2),
      ('Charcoal', 3),
    ])
      BackgroundPalette(
        name: name,
        darkBackground: Palette.variants[index].$2.ground,
        darkCard: Palette.variants[index].$2.card,
        darkInputFill: Palette.variants[index].$2.ground2,
        lightBackground: Palette.variants[index].$1.ground,
        lightCard: Palette.variants[index].$1.card,
      ),
  ];

  static ThemeData lightTheme({int paletteIndex = 0}) =>
      _themeFor(Brightness.light, paletteIndex);

  static ThemeData darkTheme({int paletteIndex = 0}) =>
      _themeFor(Brightness.dark, paletteIndex);

  static ThemeData _themeFor(Brightness brightness, int paletteIndex) {
    final p = Palette.resolve(paletteIndex, brightness);

    // Start from a generated scheme (so every niche Material slot has a sane
    // value), then override every slot the design actually cares about with
    // the literal token. This is the crux of the redesign: previously these
    // slots held algorithm output, so screens reading `scheme.onSurfaceVariant`
    // et al could never render the designed palette. Now they do - which fixes
    // the whole app at once instead of per-call-site.
    final generated = ColorScheme.fromSeed(
      seedColor: defaultSeedColor,
      brightness: brightness,
    );
    final colorScheme = generated.copyWith(
      // One accent, always: the fern green.
      //
      // This used to follow a user-selectable accent color, which is what
      // made the built app diverge from its design so persistently. Picking
      // (say) a blue accent repainted `primary` - the nav bar, segmented
      // controls, section headings - while every hand-authored token (the
      // care ring, the water button, the overdue coral) stayed green. The
      // result read as two half-finished themes fighting, not as a choice.
      // The brand accent is part of the app's identity, so it is no longer
      // configurable; theme mode and the ground palette still are.
      primary: p.fern,
      onPrimary: Colors.white,
      primaryContainer: p.fernSoft,
      onPrimaryContainer: p.fern,
      secondary: p.sage,
      onSecondary: Colors.white,
      // Neutrals carry the design's character, so they are always literal.
      surface: p.ground,
      onSurface: p.ink,
      onSurfaceVariant: p.inkSoft,
      surfaceContainerLowest: p.ground2,
      surfaceContainerLow: p.ground,
      surfaceContainer: p.card,
      surfaceContainerHigh: p.card,
      surfaceContainerHighest: p.ground2,
      outline: p.inkFaint,
      outlineVariant: p.line,
      // `error` stays a true red, reserved for destructive actions and
      // validation - deliberately NOT the coral used for overdue care, so the
      // two never get confused for each other.
      error: brightness == Brightness.dark
          ? const Color(0xFFE5766B)
          : const Color(0xFFB3261E),
      // The last two generated slots. Left algorithmic they came out as a
      // pink-mauve container that belonged to no part of this palette; the
      // soft coral is the tone the design already uses for "something is
      // wrong here".
      errorContainer: p.coralSoft,
      onErrorContainer: brightness == Brightness.dark
          ? const Color(0xFFE5766B)
          : const Color(0xFFB3261E),
    );

    final baseTextTheme = (brightness == Brightness.dark
            ? GoogleFonts.interTextTheme(
              ThemeData(brightness: Brightness.dark).textTheme,
            )
            : GoogleFonts.interTextTheme())
        .apply(bodyColor: p.ink, displayColor: p.ink);

    final cardColor = p.card;

    // Button labels must be derived from the text theme, not written fresh.
    //
    // A bare `TextStyle(fontSize: .., fontWeight: ..)` in a ButtonStyle
    // carries no font family, and the resolved button label does not always
    // sit under an ancestor that re-supplies one - so labels silently
    // rendered in the platform default face instead of Inter. Deriving from
    // labelLarge keeps every button in the app's typography.
    final buttonTextStyle = (baseTextTheme.labelLarge ?? const TextStyle())
        .copyWith(fontSize: 15.5, fontWeight: FontWeight.w700);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.ground,
      canvasColor: p.ground,
      dividerColor: p.line,
      textTheme: baseTextTheme,
      // The literal design tokens, reachable anywhere via `context.palette`.
      extensions: <ThemeExtension<dynamic>>[p],
      dividerTheme: DividerThemeData(
        color: p.hairline,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.ground,
        foregroundColor: p.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Serif display type for every screen title - the one editorial
        // touch that's shared infrastructure (FrostedAppBar), so every
        // screen picks it up without a per-screen change.
        titleTextStyle: GoogleFonts.lora(
          fontSize: 26,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
          color: p.ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
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
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          side: BorderSide(color: p.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: buttonTextStyle.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.fern,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: buttonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.fern,
          textStyle: buttonTextStyle.copyWith(fontWeight: FontWeight.w600),
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
      // Outlined, not filled.
      //
      // The fill was the recessed ground tone, which read correctly when a
      // field sat directly on the page. Now that forms group their fields
      // inside cards, that same fill rendered as a grey block inside a white
      // panel - a box in a box. An outline instead takes the color of
      // whatever surface it is on, so one treatment works on the page, in a
      // card, and in a dialog. The focused state picks up the fern accent so
      // the active field is unmistakable.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.fern, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
        labelStyle: TextStyle(color: p.inkSoft),
        floatingLabelStyle: TextStyle(color: p.fern),
        hintStyle: TextStyle(color: p.inkFaint),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
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
