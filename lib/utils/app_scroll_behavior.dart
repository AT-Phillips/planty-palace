import 'package:flutter/material.dart';

/// iOS-style scrolling everywhere: bouncing physics gives the longer,
/// smoother momentum/fling users expect on iPhone (clamping physics stops
/// abruptly, which felt short). `AlwaysScrollableScrollPhysics` keeps lists
/// draggable even when their content is shorter than the viewport, so
/// pull-to-refresh-style gestures and keyboard-dismiss-on-drag still work.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
