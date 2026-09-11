import 'package:flutter/material.dart';

import '../styles/app_theme.dart';
import 'primitives.dart';
import 'section_header.dart';

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
    final p = context.palette;

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: dividerIndent,
            color: p.hairline,
          ),
        );
      }
    }

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) SectionHeader(header!),
          AppCard(
            padding: EdgeInsets.zero,
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

  /// Overrides the title's text color - e.g. the destructive error color for
  /// a "Delete Account" row. Defaults to the normal on-surface text color.
  final Color? titleColor;
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
    this.titleColor,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final chevron = showChevron ?? (onTap != null);
    final tint = iconColor ?? p.fern;

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
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: tint),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: titleColor ?? p.ink,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (value != null)
            Text(
              value!,
              style: TextStyle(fontSize: 14, color: p.inkFaint),
            ),
          if (chevron) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: p.inkFaint),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

/// A settings row whose trailing control is a switch.
///
/// Replaces [SwitchListTile], which forces Material's list-tile metrics and
/// puts the whole row into the switch's tap target - so a mis-tap anywhere
/// on the row silently toggles a setting. Here the switch is the control and
/// the row is just layout, matching the rest of [InsetGroup].
class InsetSwitchRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const InsetSwitchRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 12, 11),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: p.fern.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: p.fern),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: p.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12.5, color: p.inkFaint),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: p.fern,
          ),
        ],
      ),
    );
  }
}
