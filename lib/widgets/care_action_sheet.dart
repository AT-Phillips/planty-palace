import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../styles/app_theme.dart';
import '../utils/care_kind.dart';
import 'app_bottom_sheet.dart';
import 'care_ring_tile.dart';
import 'slide_to_confirm.dart';

/// What the user chose to do from a [showCareActionSheet].
enum CareSheetResult { logged, editSchedule }

/// Raises the signature care-logging sheet for a single [CareKind] on a
/// plant: a large urgency ring, the current status, a slide-to-confirm to log
/// the action, and a link to adjust the schedule. Returns [CareSheetResult]
/// (or null if dismissed) so the caller performs the actual repository work -
/// keeping this surface purely presentational and reusable from both the
/// plant-detail screen and the Care list.
Future<CareSheetResult?> showCareActionSheet(
  BuildContext context, {
  required Plant plant,
  required CareKind kind,
}) {
  return showAppSheet<CareSheetResult>(
    context,
    builder: (context) => _CareActionSheet(plant: plant, kind: kind),
  );
}

class _CareActionSheet extends StatelessWidget {
  final Plant plant;
  final CareKind kind;

  const _CareActionSheet({required this.plant, required this.kind});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = CareRingTile.urgencyColor(context, kind, plant);
    final fraction = CareRingTile.progressFraction(kind, plant);
    final interval = kind.intervalDays(plant);

    final subtitle = StringBuffer(kind.statusText(plant));
    if (interval != null) {
      subtitle.write(' · every $interval day${interval == 1 ? '' : 's'}');
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: CircularProgressIndicator(
                      value: fraction,
                      strokeWidth: 5,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Icon(kind.icon, size: 34, color: color),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${kind.label} ${plant.name}',
              style: AppTheme.plantNameStyle(context, size: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            SlideToConfirm(
              label: 'Slide to mark ${kind.pastTense.toLowerCase()}',
              color: color,
              onConfirmed: () async {
                Navigator.of(context).pop(CareSheetResult.logged);
              },
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed:
                  () => Navigator.of(context).pop(CareSheetResult.editSchedule),
              child: const Text('Edit schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
