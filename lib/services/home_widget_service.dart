import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import '../models/plant.dart';
import '../utils/fertilizing_status.dart';
import '../utils/watering_status.dart';
import 'plant_repository.dart';

/// Pushes "what needs care today" data into the shared App Group storage
/// the iOS home screen widget (ios/ThicketWidget) reads from. Any failure
/// here is silent/non-blocking - the widget just shows stale data until the
/// next successful refresh, same defensive posture as every other optional
/// enrichment in this app.
class HomeWidgetService {
  static const _appGroupId = 'group.com.austinphillips.thicket';
  static const _widgetKind = 'ThicketWidget';
  static const _countKey = 'widget_plant_count';
  static const _plantsKey = 'widget_plants_json';

  /// The sooner of watering/fertilizing due-in-days for a plant (whichever
  /// is more urgent), or null if neither has a schedule. Mirrors
  /// CareScreen's sort logic.
  int? _mostUrgentDueIn(Plant plant) {
    final watering = daysUntilDue(plant);
    final fertilizing = daysUntilFertilizeDue(plant);
    if (watering == null) return fertilizing;
    if (fertilizing == null) return watering;
    return watering < fertilizing ? watering : fertilizing;
  }

  String _statusFor(Plant plant, int urgency) {
    final watering = daysUntilDue(plant);
    final useWatering = watering != null && watering == urgency;
    return useWatering
        ? wateringStatusText(plant)
        : fertilizingStatusText(plant);
  }

  Future<void> refresh() async {
    try {
      final plants = await PlantRepository().getPlants();

      final due = <MapEntry<Plant, int>>[];
      for (final plant in plants) {
        final urgency = _mostUrgentDueIn(plant);
        if (urgency != null && urgency <= 0) due.add(MapEntry(plant, urgency));
      }
      due.sort((a, b) => a.value.compareTo(b.value));

      final summary =
          due
              .take(3)
              .map(
                (e) => {
                  'name': e.key.name,
                  'status': _statusFor(e.key, e.value),
                },
              )
              .toList();

      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData<int>(_countKey, due.length);
      await HomeWidget.saveWidgetData<String>(_plantsKey, jsonEncode(summary));
      await HomeWidget.updateWidget(iOSName: _widgetKind);
    } catch (_) {
      // Widget just shows stale data until the next successful refresh.
    }
  }
}
