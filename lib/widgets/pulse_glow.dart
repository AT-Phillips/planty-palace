import 'package:flutter/material.dart';

/// Wraps a child in a slow, looping "breathing" glow — an expanding, fading
/// halo behind it — used to draw the eye to something that needs attention
/// (an overdue water button, a due-now badge) without a jarring blink. When
/// [active] is false it renders the child untouched, so callers can bind it
/// straight to an "is overdue" flag.
///
/// The glow is a shadow behind an opaque child, so [borderRadius] should match
/// the child's own shape for the halo to sit correctly around it.
class PulseGlow extends StatefulWidget {
  final Widget child;
  final bool active;
  final Color color;
  final BorderRadius borderRadius;

  /// Peak blur/spread of the halo at the top of each breath.
  final double maxBlur;
  final double maxSpread;
  final Duration period;

  const PulseGlow({
    super.key,
    required this.child,
    required this.active,
    required this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.maxBlur = 14,
    this.maxSpread = 6,
    this.period = const Duration(milliseconds: 1800),
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseGlow old) {
    super.didUpdateWidget(old);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final t = curve.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15 + 0.35 * t),
                blurRadius: widget.maxBlur * t,
                spreadRadius: widget.maxSpread * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
