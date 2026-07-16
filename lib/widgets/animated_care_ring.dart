import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular progress ring that *draws itself on* — sweeping from empty to
/// its target fraction when it first appears (optionally after a stagger
/// [delay]), and smoothly re-animating whenever [fraction] changes (e.g. after
/// logging care). Replaces the static `CircularProgressIndicator` used across
/// the care surfaces so urgency reads as a living gauge, not a frozen bar.
///
/// [child] (typically the care-kind icon) is centered inside the ring.
class AnimatedCareRing extends StatefulWidget {
  final double fraction;
  final Color color;
  final Color trackColor;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final Duration duration;
  final Duration delay;

  const AnimatedCareRing({
    super.key,
    required this.fraction,
    required this.color,
    required this.trackColor,
    this.size = 40,
    this.strokeWidth = 3,
    this.child,
    this.duration = const Duration(milliseconds: 750),
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedCareRing> createState() => _AnimatedCareRingState();
}

class _AnimatedCareRingState extends State<AnimatedCareRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = _tween(0, widget.fraction);
    if (widget.delay == Duration.zero) {
      _controller.forward();
      _started = true;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
          setState(() => _started = true);
        }
      });
    }
  }

  Animation<double> _tween(double begin, double end) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(AnimatedCareRing old) {
    super.didUpdateWidget(old);
    if (old.fraction != widget.fraction) {
      _animation = _tween(_animation.value, widget.fraction);
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return CustomPaint(
                size: Size.square(widget.size),
                painter: _RingPainter(
                  fraction: _started ? _animation.value : 0,
                  color: widget.color,
                  trackColor: widget.trackColor,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (fraction <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
