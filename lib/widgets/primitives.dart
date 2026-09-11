/// Thicket's bespoke component vocabulary.
///
/// **Why this exists.** Palette tokens fixed the app's *colors*, but the app
/// was still assembled from stock Material components - `Card`, `ListTile`,
/// `ExpansionTile`, `FilterChip`, `SegmentedButton`, `AlertDialog`. Those
/// carry hardcoded *geometry* that no [ThemeData] can override: `ListTile`'s
/// fixed 56/72dp heights and 16dp gutters, `ExpansionTile`'s centred chevron
/// and built-in dividers, `FilterChip`'s 32dp stadium and check icon. A
/// perfectly themed `ExpansionTile` still reads instantly as "a Flutter app",
/// because the proportions are Material's, not ours.
///
/// These primitives replace that vocabulary with shapes the design actually
/// specifies. They are deliberately plain widgets built from
/// `Container`/`Row`/`InkWell` so every dimension is ours to choose.
library;

import 'package:flutter/material.dart';

import '../styles/app_theme.dart';
import '../utils/haptics.dart';

/// The app's radius scale. Using a scale (rather than a per-call-site number)
/// is what makes surfaces feel like one family instead of a pile of rounded
/// rectangles that happen to coexist.
abstract final class AppRadius {
  /// Chips, badges, small inline surfaces.
  static const double sm = 12;

  /// Rows and nested surfaces sitting inside a card.
  static const double md = 18;

  /// The standard card.
  static const double lg = 22;

  /// Hero surfaces and modal sheets.
  static const double xl = 28;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// The app's spacing scale. Modern layouts read as designed largely because
/// their whitespace is *quantised* - gaps come from a small set of related
/// values rather than whatever number looked right at the time.
abstract final class Gap {
  static const Widget xs = SizedBox(height: 4, width: 4);
  static const Widget sm = SizedBox(height: 8, width: 8);
  static const Widget md = SizedBox(height: 14, width: 14);
  static const Widget lg = SizedBox(height: 22, width: 22);
  static const Widget xl = SizedBox(height: 34, width: 34);

  /// The screen's horizontal gutter. One value, used everywhere, so every
  /// screen's content shares a single left edge.
  static const double screen = 20;
}

/// The standard surface: a rounded, softly shadowed panel in the palette's
/// card tone.
///
/// Replaces Material's [Card], which forces its own margin, applies an
/// elevation *tint* over the color you asked for, and paints a uniform drop
/// shadow. This paints the designed two-layer shadow instead, takes no margin
/// of its own (the caller owns its spacing), and optionally springs on press.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;

  /// Overrides the card tone - e.g. the coral "needs care" banner.
  final Color? color;

  /// Draws a hairline border. Used for quiet, secondary surfaces that
  /// should not compete with a shadowed card.
  final bool bordered;

  /// Drops the shadow. For cards nested inside another card, where a second
  /// shadow reads as muddy rather than layered.
  final bool flat;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.radius = AppRadius.lg,
    this.color,
    this.bordered = false,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final br = BorderRadius.circular(radius);

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: br,
        border: bordered ? Border.all(color: p.line, width: 1) : null,
        boxShadow: flat || bordered ? null : p.shadowLo,
      ),
      // The ink layer sits *inside* the decoration so the splash is clipped
      // to the same radius the shadow is drawn around.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: br,
        clipBehavior: Clip.antiAlias,
        child:
            onTap == null && onLongPress == null
                ? Padding(padding: padding, child: child)
                : InkWell(
                  onTap:
                      onTap == null
                          ? null
                          : () {
                            Haptics.selection();
                            onTap!();
                          },
                  onLongPress: onLongPress,
                  borderRadius: br,
                  child: Padding(padding: padding, child: child),
                ),
      ),
    );

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }
    return surface;
  }
}

/// A content row: leading visual, a title/subtitle stack, and a trailing
/// control.
///
/// Replaces [ListTile], whose height is quantised to Material's 48/56/72dp
/// steps and whose text styles come from the text theme's `bodyLarge`/
/// `bodyMedium`. This sets its own rhythm - a tighter title/subtitle pair in
/// the palette's ink hierarchy, and padding driven by content rather than by
/// a fixed row height.
class AppRow extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;

  /// Renders the subtitle in the urgent coral - for an overdue care line.
  final bool subtitleUrgent;

  /// Renders the title in the app's serif face. Used where the title is a
  /// *plant's name* rather than UI furniture - the editorial voice that
  /// separates content from chrome.
  final bool serifTitle;

  /// Renders the subtitle in italic - a species name under a plant name.
  final bool subtitleItalic;

  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool chevron;
  final EdgeInsetsGeometry padding;

  const AppRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.subtitleUrgent = false,
    this.serifTitle = false,
    this.subtitleItalic = false,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.chevron = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final content = Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, Gap.md],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      serifTitle
                          ? AppTheme.plantNameStyle(context, size: 16)
                          : TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: p.ink,
                            height: 1.2,
                          ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.25,
                      fontStyle:
                          subtitleItalic ? FontStyle.italic : FontStyle.normal,
                      fontWeight:
                          subtitleUrgent ? FontWeight.w600 : FontWeight.w400,
                      color: subtitleUrgent ? p.coral : p.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[Gap.sm, trailing!],
          if (chevron) ...[
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 20, color: p.inkFaint),
          ],
        ],
      ),
    );

    if (onTap == null && onLongPress == null) return content;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap:
            onTap == null
                ? null
                : () {
                  Haptics.selection();
                  onTap!();
                },
        onLongPress: onLongPress,
        child: content,
      ),
    );
  }
}

/// A sliding-pill tab control.
///
/// Replaces [SegmentedButton], whose outlined-pill-row shape (plus its
/// selected checkmark and Material state layers) is one of the most
/// recognisable "this is a stock Material app" signals. This is the pattern
/// modern iOS-leaning apps actually use: a recessed trough with a single
/// filled pill that *slides* between positions.
class SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Optional icons, one per label.
  final List<IconData>? icons;

  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.icons,
  }) : assert(labels.length > 1, 'A segmented control needs 2+ segments');

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // AnimatedDefaultTextStyle *replaces* the ambient DefaultTextStyle rather
    // than merging into it, so a bare TextStyle here would silently drop the
    // app's Inter family and render these labels in the platform default
    // face. Deriving from the text theme keeps them in the app's typography.
    final baseStyle =
        Theme.of(context).textTheme.labelLarge ?? const TextStyle();

    return LayoutBuilder(
      builder: (context, constraints) {
        const trough = 4.0;
        final segmentWidth =
            (constraints.maxWidth - trough * 2) / labels.length;

        return Container(
          height: 44,
          padding: const EdgeInsets.all(trough),
          decoration: BoxDecoration(
            color: p.ground2,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            children: [
              // The travelling pill. Animating a single positioned child
              // (rather than cross-fading two states) is what makes the
              // control feel physical.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: segmentWidth * selected,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: p.shadowLo,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (i == selected) return;
                          Haptics.selection();
                          onChanged(i);
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: baseStyle.copyWith(
                              fontSize: 13.5,
                              fontWeight:
                                  i == selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              color: i == selected ? p.ink : p.inkSoft,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (icons != null) ...[
                                  Icon(
                                    icons![i],
                                    size: 15,
                                    color: i == selected ? p.fern : p.inkFaint,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    labels[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A compact toggle pill.
///
/// Replaces [FilterChip]/[ActionChip], which impose a 32dp stadium, a leading
/// checkmark on selection, and a Material state overlay. This is a quieter
/// shape: a hairline-bordered pill that fills with the soft accent tint when
/// active, with no checkmark.
class FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Tints the active state with the urgent coral instead of fern - for the
  /// "Overdue only" filter, where the filter and the thing it filters for
  /// should read as the same signal.
  final bool urgent;

  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = urgent ? p.coral : p.fern;
    final fill = urgent ? p.coralSoft : p.fernSoft;

    return GestureDetector(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(icon == null ? 14 : 11, 8, 14, 8),
        decoration: BoxDecoration(
          color: selected ? fill : p.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.45) : p.line,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? accent : p.inkSoft),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? accent : p.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small, quiet inline button - the trailing "Sort" / "All spaces" control
/// on a filter bar.
///
/// Replaces the bare `PopupMenuButton` + `Row(Icon, Text)` pattern, which
/// rendered as unpadded raw text with no affordance that it was tappable.
class InlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool trailingCaret;

  const InlineButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailingCaret = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 8, 9, 8),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: p.line, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: p.inkSoft),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 108),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: p.inkSoft,
                ),
              ),
            ),
            if (trailingCaret)
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: p.inkFaint,
              ),
          ],
        ),
      ),
    );
  }
}

/// A circular icon button on a soft tinted disc - the water/care action on a
/// row.
///
/// Replaces `IconButton` + `IconButton.styleFrom(backgroundColor: ...)`,
/// which carries a 48dp minimum tap target that forces rows taller than the
/// design wants and paints a Material state overlay over the tint.
class CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final String? tooltip;

  /// Fills the disc with [color] and inverts the icon to white - for the
  /// primary action on an urgent row.
  final bool filled;

  const CircleAction({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 38,
    this.tooltip,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTap: () {
        Haptics.light();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.13),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: size * 0.47,
          color: filled ? Colors.white : color,
        ),
      ),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// A collapsible group - a header row that expands to reveal its children.
///
/// Replaces [ExpansionTile], whose fixed 56dp header height, centred trailing
/// chevron, and automatic top/bottom dividers are unthemeable. This uses the
/// app's own row rhythm, a rotating chevron, and a count "pip" in place of a
/// subtitle line - so a hub section reads as designed content rather than a
/// settings page.
class AppExpander extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;

  /// Optional trailing control shown in the header, left of the chevron.
  final Widget? headerAction;

  /// Optional leading visual (a thumbnail, an icon tile).
  final Widget? leading;

  final EdgeInsetsGeometry margin;

  const AppExpander({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
    this.headerAction,
    this.leading,
    this.margin = const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, 12),
  });

  @override
  State<AppExpander> createState() => _AppExpanderState();
}

class _AppExpanderState extends State<AppExpander>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.initiallyExpanded ? 1 : 0,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    Haptics.selection();
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppCard(
      padding: EdgeInsets.zero,
      margin: widget.margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  widget.leading == null ? 18 : 12,
                  13,
                  14,
                  13,
                ),
                child: Row(
                  children: [
                    if (widget.leading != null) ...[widget.leading!, Gap.md],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: p.inkFaint),
                          ),
                        ],
                      ),
                    ),
                    if (widget.headerAction != null) widget.headerAction!,
                    RotationTransition(
                      turns: Tween<double>(
                        begin: 0,
                        end: 0.5,
                      ).animate(_curve),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: p.inkFaint,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _curve,
            child: FadeTransition(
              opacity: _curve,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(height: 1, thickness: 1, color: p.hairline),
                  ...widget.children,
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A floating primary action, shaped as a labelled pill.
///
/// Replaces [FloatingActionButton]. Material's FAB is a circle carrying a
/// bare icon, with a fixed 56dp diameter and its own elevation model - and
/// in this app it also collided visually with the round camera disc already
/// anchored in the bottom navigation bar, so two different circles competed
/// for "the add button". A labelled pill says what it does, and reads as
/// part of this app rather than as the framework's default.
class FloatingActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const FloatingActionPill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: p.shadowHi,
        ),
        child: Material(
          color: p.fern,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: () {
              Haptics.light();
              onPressed();
            },
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 15, 22, 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 19, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
