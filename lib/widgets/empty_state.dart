import 'package:flutter/material.dart';

import '../styles/app_theme.dart';

/// A polished empty-state placeholder: icon in a soft circle, a title,
/// supporting copy, and an optional call-to-action — instead of a single
/// plain line of centered text floating in dead space.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Center within the available space, but fall back to scrolling if that
    // space is shorter than the content (small screens, or when a segmented
    // control/keyboard shrinks the area) instead of overflowing.
    return LayoutBuilder(
      builder:
          (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A soft fern disc rather than the recessed ground tone,
                    // which was very nearly invisible against the page.
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: p.fernSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 42, color: p.fern),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      style: AppTheme.plantNameStyle(context, size: 21),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: p.inkSoft,
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
