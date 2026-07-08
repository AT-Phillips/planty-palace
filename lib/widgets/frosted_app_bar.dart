import 'dart:ui';

import 'package:flutter/material.dart';

/// A fixed-height frosted-glass app bar — used consistently across every
/// screen instead of a collapsing large title, since that pattern needs
/// substantial scrollable content to animate smoothly and snaps abruptly
/// otherwise, which happens easily in an app where a user's collection
/// (Spaces, plants) can legitimately be short.
class FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final double? leadingWidth;

  const FrostedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.leadingWidth,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AppBar(
          title: Text(title),
          actions: actions,
          leading: leading,
          leadingWidth: leadingWidth,
          backgroundColor: scheme.surface.withValues(alpha: 0.7),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }
}
