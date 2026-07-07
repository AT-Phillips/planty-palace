import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../utils/watering_status.dart';
import 'plant_thumbnail.dart';

/// A plant thumbnail encircled by a watering-urgency ring: the ring fills as
/// the next watering approaches and shifts green -> amber -> red (red once
/// overdue), so the Care list reads at a glance. Falls back to a plain
/// circular thumbnail when the plant has no watering schedule.
class CareRing extends StatelessWidget {
  final Plant plant;
  final double size;
  final Object? heroTag;

  const CareRing({super.key, required this.plant, this.size = 52, this.heroTag});

  static const _green = Color(0xFF3FA34D);
  static const _amber = Color(0xFFE0A100);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final interval = plant.wateringIntervalDays;
    final days = daysUntilDue(plant);

    double? fraction;
    Color ringColor = _green;
    if (interval != null && interval > 0 && days != null) {
      fraction = ((interval - days) / interval).clamp(0.0, 1.0);
      if (days < 0) {
        ringColor = scheme.error;
        fraction = 1.0;
      } else if (fraction >= 0.75) {
        ringColor = _amber;
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

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: fraction,
              strokeWidth: 3,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            ),
          ),
          thumb,
        ],
      ),
    );
  }
}
