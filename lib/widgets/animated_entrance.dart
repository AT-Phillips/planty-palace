import 'package:flutter/material.dart';

/// Fades and lifts its [child] into place on first build — the app-wide
/// "settle-in" motion. Give sibling items an increasing [index] and they
/// enter in a staggered sequence rather than popping in all at once.
///
/// The stagger is capped internally so long lists never make the last item
/// wait an absurd amount; items past the cap all share the final delay.
class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration baseDelay;
  final Duration perItem;
  final double offsetY;

  /// Caps how many items are individually staggered before the delay plateaus.
  final int maxStagger;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 420),
    this.baseDelay = Duration.zero,
    this.perItem = const Duration(milliseconds: 55),
    this.offsetY = 12,
    this.maxStagger = 10,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final steps = widget.index.clamp(0, widget.maxStagger);
    final delay = widget.baseDelay + widget.perItem * steps;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        return Opacity(
          opacity: _curve.value,
          child: Transform.translate(
            offset: Offset(0, widget.offsetY * (1 - _curve.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
