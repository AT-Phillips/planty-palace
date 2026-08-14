import 'dart:ui';

import 'package:flutter/material.dart';

import '../styles/app_theme.dart';

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

  /// Slightly taller than [kToolbarHeight] to give the 26px serif large
  /// title the breathing room the design calls for.
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AppBar(
          toolbarHeight: 64,
          title: Text(title),
          actions: actions,
          leading: leading,
          leadingWidth: leadingWidth,
          // Translucent ground so content frosts under it as it scrolls.
          backgroundColor: p.ground.withValues(alpha: 0.72),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
    );
  }
}
