import 'package:flutter/material.dart';

/// Thicket's literal design tokens.
///
/// **Why this exists.** The app previously derived nearly every color from
/// `ColorScheme.fromSeed(...)`, which *algorithmically generates* ~30 colors
/// from a single seed. That meant the hand-picked values from the visual
/// direction study (the misty-sage ground, the fern accent, the coral overdue
/// signal) were discarded and replaced by Material's tonal-palette math - so
/// the built app could never actually look like the design, only "similar".
///
/// [Palette] holds those values *literally*. Screens read design decisions
/// from here; the Material [ColorScheme] is kept only so stock widgets
/// (buttons, switches, text fields) still have sane defaults.
///
/// Read it with `context.palette` (see the extension at the bottom).
///
/// **Semantics are fixed, decoration is themeable.** The care signal colors
/// (fern = healthy, amber = due soon, coral = overdue) are identical in every
/// variant, because they carry *meaning* - a user shouldn't be able to pick a
/// theme that makes "overdue" and "healthy" hard to tell apart. Only the
/// ground/card/ink family changes between variants.
@immutable
class Palette extends ThemeExtension<Palette> {
  /// The page background - what the whole app sits on.
  final Color ground;

  /// A slightly deeper ground, for recessed areas (segmented control troughs).
  final Color ground2;

  /// Standard card/sheet surface, one step above [ground].
  final Color card;

  /// A lifted surface for things that float above cards (modal sheets).
  final Color cardRaised;

  /// Primary text.
  final Color ink;

  /// Secondary text - subtitles, species names, supporting detail.
  final Color inkSoft;

  /// Tertiary text - uppercase section labels, captions, disabled states.
  final Color inkFaint;

  /// Visible dividers and progress-track backgrounds.
  final Color line;

  /// Barely-there separators inside grouped lists.
  final Color hairline;

  /// The deep brand green. Used for brand moments, not for interaction.
  final Color sage;

  /// The live/interactive accent - primary actions and active states.
  final Color fern;

  /// A soft fern-tinted fill, for accent chips and identified-species cards.
  final Color fernSoft;

  /// Care ring color when a schedule is comfortably in the future.
  final Color mintRing;

  /// Overdue care. Deliberately distinct from [amber] and from the
  /// destructive-action red, so all three read as separate signals.
  final Color coral;

  /// Soft coral fill - the "needs care" banner.
  final Color coralSoft;

  /// Due-soon care, and the toxicity warning.
  final Color amber;

  /// Soft amber fill.
  final Color amberSoft;

  /// The permanently-dark bottom navigation anchor.
  final Color nav;

  /// Inactive icon/label color on the dark [nav] bar.
  final Color navInk;

  /// Resting elevation for cards and rows.
  final List<BoxShadow> shadowLo;

  /// Pronounced elevation for floating/modal surfaces.
  final List<BoxShadow> shadowHi;

  const Palette({
    required this.ground,
    required this.ground2,
    required this.card,
    required this.cardRaised,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.line,
    required this.hairline,
    required this.sage,
    required this.fern,
    required this.fernSoft,
    required this.mintRing,
    required this.coral,
    required this.coralSoft,
    required this.amber,
    required this.amberSoft,
    required this.nav,
    required this.navInk,
    required this.shadowLo,
    required this.shadowHi,
  });

  // ---------------------------------------------------------------------
  // Semantic constants - identical across every variant and brightness pair
  // beyond the light/dark lift, because they encode meaning rather than taste.
  // ---------------------------------------------------------------------

  static const _fernLight = Color(0xFF1F9D63);
  static const _fernDark = Color(0xFF45C486);
  static const _fernSoftLight = Color(0xFFE4F3EA);
  static const _fernSoftDark = Color(0xFF172C22);
  static const _sageLight = Color(0xFF2E6B4F);
  static const _sageDark = Color(0xFF6FBE95);
  static const _mintLight = Color(0xFF33B579);
  static const _mintDark = Color(0xFF52D095);
  static const _coralLight = Color(0xFFDB5F38);
  static const _coralDark = Color(0xFFE8825F);
  static const _coralSoftLight = Color(0xFFF8E4DC);
  static const _coralSoftDark = Color(0xFF2E1E18);
  static const _amberLight = Color(0xFFB7841F);
  static const _amberDark = Color(0xFFD6AC5A);
  static const _amberSoftLight = Color(0xFFF5EAD2);
  static const _amberSoftDark = Color(0xFF2C2414);

  static const List<BoxShadow> _shadowLoLight = [
    BoxShadow(
      color: Color(0x0F14201A),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0D14201A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  static const List<BoxShadow> _shadowHiLight = [
    BoxShadow(
      color: Color(0x2414201A),
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];
  static const List<BoxShadow> _shadowLoDark = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
  static const List<BoxShadow> _shadowHiDark = [
    BoxShadow(
      color: Color(0x8C000000),
      blurRadius: 34,
      offset: Offset(0, 10),
    ),
  ];

  /// Builds a variant from just its ground/card/ink family, holding every
  /// semantic (care) color constant. Keeps the variants honestly *designed*
  /// rather than algorithmically derived, while guaranteeing that urgency
  /// always reads the same way no matter which look the user picks.
  factory Palette._variant({
    required Brightness brightness,
    required Color ground,
    required Color ground2,
    required Color card,
    required Color cardRaised,
    required Color ink,
    required Color inkSoft,
    required Color inkFaint,
    required Color line,
    required Color nav,
    required Color navInk,
  }) {
    final isDark = brightness == Brightness.dark;
    return Palette(
      ground: ground,
      ground2: ground2,
      card: card,
      cardRaised: cardRaised,
      ink: ink,
      inkSoft: inkSoft,
      inkFaint: inkFaint,
      line: line,
      hairline:
          isDark ? const Color(0x12FFFFFF) : const Color(0x1414201A),
      sage: isDark ? _sageDark : _sageLight,
      fern: isDark ? _fernDark : _fernLight,
      fernSoft: isDark ? _fernSoftDark : _fernSoftLight,
      mintRing: isDark ? _mintDark : _mintLight,
      coral: isDark ? _coralDark : _coralLight,
      coralSoft: isDark ? _coralSoftDark : _coralSoftLight,
      amber: isDark ? _amberDark : _amberLight,
      amberSoft: isDark ? _amberSoftDark : _amberSoftLight,
      nav: nav,
      navInk: navInk,
      shadowLo: isDark ? _shadowLoDark : _shadowLoLight,
      shadowHi: isDark ? _shadowHiDark : _shadowHiLight,
    );
  }

  // ---------------------------------------------------------------------
  // Forest - the default, and the exact palette from the direction study.
  // ---------------------------------------------------------------------

  static final forestLight = Palette._variant(
    brightness: Brightness.light,
    ground: const Color(0xFFE7EDE6),
    ground2: const Color(0xFFDEE6DC),
    card: const Color(0xFFFBFCFA),
    cardRaised: const Color(0xFFFFFFFF),
    ink: const Color(0xFF14201A),
    inkSoft: const Color(0xFF5C6A61),
    inkFaint: const Color(0xFF8A968C),
    line: const Color(0xFFDDE4DB),
    nav: const Color(0xFF131A16),
    navInk: const Color(0xFFC7CFC5),
  );

  static final forestDark = Palette._variant(
    brightness: Brightness.dark,
    ground: const Color(0xFF0C1310),
    ground2: const Color(0xFF0A100D),
    card: const Color(0xFF18211C),
    cardRaised: const Color(0xFF1F2A24),
    ink: const Color(0xFFE9F0E8),
    inkSoft: const Color(0xFF9BA89E),
    inkFaint: const Color(0xFF6E7B71),
    line: const Color(0xFF26312A),
    nav: const Color(0xFF060A08),
    navInk: const Color(0xFFB9C2B7),
  );

  // ---------------------------------------------------------------------
  // Midnight / Slate / Charcoal - alternate ground families, each given the
  // same treatment as Forest (a real ink hierarchy, a real card lift) rather
  // than being a tinted copy.
  // ---------------------------------------------------------------------

  static final midnightLight = Palette._variant(
    brightness: Brightness.light,
    ground: const Color(0xFFE4EAF2),
    ground2: const Color(0xFFDAE2EC),
    card: const Color(0xFFFAFBFD),
    cardRaised: const Color(0xFFFFFFFF),
    ink: const Color(0xFF141B26),
    inkSoft: const Color(0xFF5A6675),
    inkFaint: const Color(0xFF8A94A2),
    line: const Color(0xFFDBE2EA),
    nav: const Color(0xFF121822),
    navInk: const Color(0xFFC5CCD6),
  );

  static final midnightDark = Palette._variant(
    brightness: Brightness.dark,
    ground: const Color(0xFF0B1018),
    ground2: const Color(0xFF080D14),
    card: const Color(0xFF161E29),
    cardRaised: const Color(0xFF1E2733),
    ink: const Color(0xFFE7ECF3),
    inkSoft: const Color(0xFF98A3B2),
    inkFaint: const Color(0xFF6C7787),
    line: const Color(0xFF242E3B),
    nav: const Color(0xFF05080D),
    navInk: const Color(0xFFB6BECA),
  );

  static final slateLight = Palette._variant(
    brightness: Brightness.light,
    ground: const Color(0xFFE9EAEC),
    ground2: const Color(0xFFDFE1E4),
    card: const Color(0xFFFBFBFC),
    cardRaised: const Color(0xFFFFFFFF),
    ink: const Color(0xFF191B1E),
    inkSoft: const Color(0xFF5F646A),
    inkFaint: const Color(0xFF8D9299),
    line: const Color(0xFFDEE0E3),
    nav: const Color(0xFF16181B),
    navInk: const Color(0xFFC8CACD),
  );

  static final slateDark = Palette._variant(
    brightness: Brightness.dark,
    ground: const Color(0xFF101215),
    ground2: const Color(0xFF0C0E10),
    card: const Color(0xFF1B1E22),
    cardRaised: const Color(0xFF23272C),
    ink: const Color(0xFFEAECEE),
    inkSoft: const Color(0xFF9CA1A8),
    inkFaint: const Color(0xFF70757C),
    line: const Color(0xFF282C31),
    nav: const Color(0xFF080A0C),
    navInk: const Color(0xFFBBBFC4),
  );

  static final charcoalLight = Palette._variant(
    brightness: Brightness.light,
    ground: const Color(0xFFEDEAE4),
    ground2: const Color(0xFFE3DFD7),
    card: const Color(0xFFFCFBF8),
    cardRaised: const Color(0xFFFFFFFF),
    ink: const Color(0xFF1C1A16),
    inkSoft: const Color(0xFF63605A),
    inkFaint: const Color(0xFF918D85),
    line: const Color(0xFFE1DDD5),
    nav: const Color(0xFF19170F),
    navInk: const Color(0xFFCCC8C0),
  );

  static final charcoalDark = Palette._variant(
    brightness: Brightness.dark,
    ground: const Color(0xFF121110),
    ground2: const Color(0xFF0D0C0B),
    card: const Color(0xFF1E1C1A),
    cardRaised: const Color(0xFF272522),
    ink: const Color(0xFFEEEBE6),
    inkSoft: const Color(0xFFA09B94),
    inkFaint: const Color(0xFF757068),
    line: const Color(0xFF2C2A27),
    nav: const Color(0xFF0A0908),
    navInk: const Color(0xFFC0BCB5),
  );

  /// All variants in picker order, paired light/dark. Index matches
  /// `AppTheme.backgroundPalettes` / `ThemeController.backgroundPaletteIndex`.
  static final List<(Palette light, Palette dark)> variants = [
    (forestLight, forestDark),
    (midnightLight, midnightDark),
    (slateLight, slateDark),
    (charcoalLight, charcoalDark),
  ];

  /// Resolves the palette for a variant index + brightness, clamping an
  /// out-of-range index to Forest rather than throwing.
  static Palette resolve(int variantIndex, Brightness brightness) {
    final pair =
        (variantIndex >= 0 && variantIndex < variants.length)
            ? variants[variantIndex]
            : variants[0];
    return brightness == Brightness.dark ? pair.$2 : pair.$1;
  }

  @override
  Palette copyWith({
    Color? ground,
    Color? ground2,
    Color? card,
    Color? cardRaised,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? line,
    Color? hairline,
    Color? sage,
    Color? fern,
    Color? fernSoft,
    Color? mintRing,
    Color? coral,
    Color? coralSoft,
    Color? amber,
    Color? amberSoft,
    Color? nav,
    Color? navInk,
    List<BoxShadow>? shadowLo,
    List<BoxShadow>? shadowHi,
  }) {
    return Palette(
      ground: ground ?? this.ground,
      ground2: ground2 ?? this.ground2,
      card: card ?? this.card,
      cardRaised: cardRaised ?? this.cardRaised,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      line: line ?? this.line,
      hairline: hairline ?? this.hairline,
      sage: sage ?? this.sage,
      fern: fern ?? this.fern,
      fernSoft: fernSoft ?? this.fernSoft,
      mintRing: mintRing ?? this.mintRing,
      coral: coral ?? this.coral,
      coralSoft: coralSoft ?? this.coralSoft,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      nav: nav ?? this.nav,
      navInk: navInk ?? this.navInk,
      shadowLo: shadowLo ?? this.shadowLo,
      shadowHi: shadowHi ?? this.shadowHi,
    );
  }

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      ground: c(ground, other.ground),
      ground2: c(ground2, other.ground2),
      card: c(card, other.card),
      cardRaised: c(cardRaised, other.cardRaised),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      inkFaint: c(inkFaint, other.inkFaint),
      line: c(line, other.line),
      hairline: c(hairline, other.hairline),
      sage: c(sage, other.sage),
      fern: c(fern, other.fern),
      fernSoft: c(fernSoft, other.fernSoft),
      mintRing: c(mintRing, other.mintRing),
      coral: c(coral, other.coral),
      coralSoft: c(coralSoft, other.coralSoft),
      amber: c(amber, other.amber),
      amberSoft: c(amberSoft, other.amberSoft),
      nav: c(nav, other.nav),
      navInk: c(navInk, other.navInk),
      shadowLo: BoxShadow.lerpList(shadowLo, other.shadowLo, t) ?? shadowLo,
      shadowHi: BoxShadow.lerpList(shadowHi, other.shadowHi, t) ?? shadowHi,
    );
  }
}

/// Ergonomic access: `context.palette.fern` instead of the full
/// `Theme.of(context).extension<Palette>()!` incantation.
extension PaletteContext on BuildContext {
  Palette get palette =>
      Theme.of(this).extension<Palette>() ?? Palette.forestLight;
}
