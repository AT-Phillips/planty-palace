import 'package:flutter/material.dart';

/// Disables iOS's rubber-band overscroll everywhere. With short content
/// (a handful of Spaces or plants, which is normal), the bounce reads as
/// content visually shifting/disappearing when scrolled past the edge and
/// held - clamping removes that regardless of content length.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
