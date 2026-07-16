import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../styles/app_theme.dart';
import '../utils/watering_status.dart';
import 'animated_care_ring.dart';
import 'plant_thumbnail.dart';

/// A plant thumbnail encircled by a watering-urgency ring that *draws itself
/// on*: the ring fills as the next watering approaches and shifts healthy
/// fern -> amber -> coral (coral once overdue), so the Care list reads at a
/// glance. Falls back to a plain circular thumbnail when the plant has no
/// watering schedule. Colors come from the shared care palette so this reads
/// identically to the plant-detail care rings.
class CareRing extends StatelessWidget {
  final Plant plant;
  final double size;
  final Object? heroTag;

  const CareRing({
    super.key,
    required this.plant,
    this.size = 52,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final interval = plant.wateringIntervalDays;
    final days = daysUntilDue(plant);

    double? fraction;
    Color ringColor = AppTheme.careHealthy(context);
    if (interval != null && interval > 0 && days != null) {
      fraction = ((interval - days) / interval).clamp(0.0, 1.0);
      if (days < 0) {
        ringColor = AppTheme.careOverdue(context);
        fraction = 1.0;
      } else if (fraction >= 0.75) {
        ringColor = AppTheme.careSoon(context);
      }
    }

    final thumb = PlantThumbnail(
      plant: plant,
      size: size - 10,
      borderRadius: BorderRadius.circular((size - 10) / 2),
      heroTag: heroTag,
    );

    if (fraction == null) {
      return SizedBox(width: size, height: size, child: Center(child: thumb));
    }

    return AnimatedCareRing(
      fraction: fraction,
      color: ringColor,
      trackColor: scheme.surfaceContainerHighest,
      size: size,
      strokeWidth: 3,
      child: thumb,
    );
  }
}
