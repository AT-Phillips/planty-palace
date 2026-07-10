import 'package:flutter/material.dart';

import '../utils/haptics.dart';

/// An iOS-style "slide to confirm" control: a pill with a draggable knob the
/// user pushes to the far end to commit an action. Used for logging care so
/// the confirmation is a deliberate, tactile gesture (with a haptic when it
/// lands) rather than a silent tap. Snaps back if released before the end.
class SlideToConfirm extends StatefulWidget {
  final String label;
  final IconData knobIcon;

  /// Fill/knob color - typically the relevant care color (fern, coral, ...).
  final Color color;

  /// Foreground (label + knob glyph) color drawn on [color].
  final Color onColor;
  final Future<void> Function() onConfirmed;

  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    required this.color,
    this.knobIcon = Icons.chevron_right,
    this.onColor = Colors.white,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> with SingleTickerProviderStateMixin {
  static const double _height = 56;
  static const double _knob = 48;
  static const double _pad = 4;

  double _dragX = 0;
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxX = constraints.maxWidth - _knob - _pad * 2;

        void onEnd() async {
          if (_dragX >= maxX * 0.85 && !_confirming) {
            setState(() {
              _confirming = true;
              _dragX = maxX;
            });
            Haptics.medium();
            await widget.onConfirmed();
          } else {
            setState(() => _dragX = 0);
          }
        }

        return GestureDetector(
          onHorizontalDragUpdate: _confirming
              ? null
              : (d) => setState(() => _dragX = (_dragX + d.delta.dx).clamp(0.0, maxX)),
          onHorizontalDragEnd: _confirming ? null : (_) => onEnd(),
          child: Container(
            height: _height,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(_height / 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Label fades as the knob advances so it never sits under it.
                Opacity(
                  opacity: (1 - (_dragX / (maxX == 0 ? 1 : maxX))).clamp(0.0, 1.0),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.onColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: _confirming || _dragX == 0
                      ? const Duration(milliseconds: 180)
                      : Duration.zero,
                  curve: Curves.easeOut,
                  left: _pad + _dragX,
                  top: _pad,
                  child: Container(
                    width: _knob,
                    height: _knob,
                    decoration: BoxDecoration(
                      color: widget.onColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _confirming ? Icons.check : widget.knobIcon,
                      color: widget.color,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
