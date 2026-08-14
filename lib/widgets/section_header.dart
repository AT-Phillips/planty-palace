import 'package:flutter/material.dart';

import '../styles/app_theme.dart';

/// The small uppercase, letter-spaced, muted label that opens a section
/// ("CARE", "GROWTH PHOTOS", "JOURNAL"), with an optional trailing action.
///
/// Replaces the accent-colored, sentence-case, default-size headings the app
/// used previously. Those read as stock Material and, because they used
/// `colorScheme.primary`, they also picked up the user's accent color - which
/// made every screen look like a themed template rather than a designed one.
/// Structural labels are *navigation furniture*, not accents, so they sit
/// quietly in [Palette.inkFaint] and let content carry the color.
class SectionHeader extends StatelessWidget {
  final String title;

  /// Optional trailing control, e.g. an "Add" button.
  final Widget? action;

  final EdgeInsetsGeometry padding;

  const SectionHeader(
    this.title, {
    super.key,
    this.action,
    this.padding = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title.toUpperCase(),
      style: AppTheme.sectionLabelStyle(context),
    );

    return Padding(
      padding: padding,
      child:
          action == null
              ? label
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [label, action!],
              ),
    );
  }
}

/// A compact text action for a [SectionHeader]'s trailing slot - visually
/// lighter than a full `TextButton.icon`, which was too heavy sitting beside
/// a small uppercase label.
class SectionAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const SectionAction({
    super.key,
    required this.label,
    this.icon = Icons.add,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final fern = context.palette.fern;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fern),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: fern,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
