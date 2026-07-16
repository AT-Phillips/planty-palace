import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../styles/app_theme.dart';
import '../utils/care_kind.dart';
import 'animated_care_ring.dart';
import 'pressable.dart';

/// A compact care tile: a progress ring (filling as the next due date
/// approaches, colored healthy -> amber -> coral by urgency) wrapped around
/// the care-kind icon, beside a label and a short status. Tapping opens the
/// care action sheet. Used in the plant-detail 2x2 care grid; reusable for
/// any at-a-glance care surface.
class CareRingTile extends StatelessWidget {
  final CareKind kind;
  final Plant plant;
  final VoidCallback onTap;

  /// Position of this tile in its grid, used to stagger the ring's draw-on
  /// animation so the tiles fill in sequence rather than all at once.
  final int index;

  const CareRingTile({
    super.key,
    required this.kind,
    required this.plant,
    required this.onTap,
    this.index = 0,
  });

  /// The urgency color for a kind on a plant: coral when overdue, amber when
  /// within the last ~20% of the interval, else the healthy fern green.
  static Color urgencyColor(BuildContext context, CareKind kind, Plant plant) {
    if (kind.overdue(plant)) return AppTheme.careOverdue(context);
    final fraction = _fraction(kind, plant);
    if (fraction != null && fraction >= 0.8) return AppTheme.careSoon(context);
    return AppTheme.careHealthy(context);
  }

  static double? _fraction(CareKind kind, Plant plant) {
    final interval = kind.intervalDays(plant);
    final days = kind.dueInDays(plant);
    if (interval == null || interval <= 0 || days == null) return null;
    if (days < 0) return 1;
    return ((interval - days) / interval).clamp(0.0, 1.0);
  }

  /// Public progress fraction (0..1) toward the next due date, defaulting to
  /// 0 when unscheduled - shared with the care action sheet's larger ring.
  static double progressFraction(CareKind kind, Plant plant) =>
      _fraction(kind, plant) ?? 0;

  String _shortStatus() {
    final days = kind.dueInDays(plant);
    if (days == null) return 'Not set';
    if (days < 0) return '${-days}d over';
    if (days == 0) return 'Today';
    return 'in ${days}d';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = urgencyColor(context, kind, plant);
    final fraction = _fraction(kind, plant) ?? 0;
    final overdue = kind.overdue(plant);

    return Pressable(
      onTap: onTap,
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AnimatedCareRing(
                fraction: fraction,
                color: color,
                trackColor: scheme.surfaceContainerHighest,
                size: 40,
                strokeWidth: 3,
                delay: Duration(milliseconds: 90 * index),
                child: Icon(kind.icon, size: 17, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      kind.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _shortStatus(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: overdue ? color : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
