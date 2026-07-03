import 'dart:ui';

import 'package:flutter/material.dart';

/// A [SliverAppBar.large] with a frosted-glass, translucent background —
/// evokes iOS17's collapsing large-title navigation bars.
class FrostedSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const FrostedSliverAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SliverAppBar.large(
      title: Text(title),
      actions: actions,
      backgroundColor: scheme.surface.withValues(alpha: 0.7),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
