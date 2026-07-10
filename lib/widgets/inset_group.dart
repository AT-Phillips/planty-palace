import 'package:flutter/material.dart';

import '../styles/app_theme.dart';

/// An iOS-style "inset grouped" section: an optional uppercase header label
/// above a single rounded card whose rows are separated by inset hairline
/// dividers. This is the backbone of the modernized forms (Add Plant) and
/// hub lists (Spaces) - replacing the stacked one-Card-per-field and dense
/// `ListTile` layouts with a calm, familiar iOS grouping.
///
/// Pass [InsetRow]s (or any widgets) as [children]. When rows have a leading
/// icon, set [dividerIndent] to ~56 so the divider starts at the text;
/// icon-less groups keep the default 16.
class InsetGroup extends StatelessWidget {
  final String? header;
  final List<Widget> children;
  final double dividerIndent;
  final EdgeInsetsGeometry margin;

  const InsetGroup({
    super.key,
    this.header,
    required this.children,
    this.dividerIndent = 16,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 18),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: dividerIndent,
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ));
      }
    }

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Text(
                header!.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, children: rows),
          ),
        ],
      ),
    );
  }
}

/// A single row inside an [InsetGroup]. Supports the common iOS shapes:
/// - a settings/detail row: leading [icon], [title], trailing [value] + chevron
/// - a plain navigation row: [title] + chevron (no icon)
/// - a custom row: provide [trailing] to override the value/chevron
class InsetRow extends StatelessWidget {
  final IconData? icon;

  /// Tint for the leading icon's rounded-square box; defaults to the fern
  /// interactive accent.
  final Color? iconColor;
  final String title;
  final String? value;

  /// Overrides the default trailing (value text + chevron) entirely.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Whether to show the trailing chevron. Defaults to true when [onTap] is
  /// set (a tappable navigation/picker row), false otherwise.
  final bool? showChevron;

  const InsetRow({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chevron = showChevron ?? (onTap != null);
    final tint = iconColor ?? AppTheme.fernColor(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: tint),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (value != null)
            Text(
              value!,
              style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
            ),
          if (chevron) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
