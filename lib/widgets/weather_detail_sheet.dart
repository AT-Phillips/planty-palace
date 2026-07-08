import 'package:flutter/material.dart';

import '../screens/location_picker_screen.dart';
import '../screens/weather_settings_screen.dart';
import '../services/location_preferences.dart';
import '../services/unit_preferences.dart';
import '../services/weather_service.dart';

/// Maps an OpenWeatherMap icon code (e.g. "10d") to a Material icon. Shared by
/// the compact WeatherCard and the detail sheet so they stay in sync.
IconData weatherIconData(String owmIconCode) {
  if (owmIconCode.length < 2) return Icons.cloud_outlined;
  final code = owmIconCode.substring(0, 2);
  final isNight = owmIconCode.endsWith('n');
  switch (code) {
    case '01':
      return isNight ? Icons.nightlight_outlined : Icons.wb_sunny_outlined;
    case '02':
    case '03':
    case '04':
      return Icons.cloud_outlined;
    case '09':
    case '10':
      return Icons.water_drop_outlined;
    case '11':
      return Icons.thunderstorm_outlined;
    case '13':
      return Icons.ac_unit_outlined;
    case '50':
      return Icons.blur_on;
    default:
      return Icons.cloud_outlined;
  }
}

/// Pops up local weather as a bottom sheet (instead of navigating to the full
/// Weather settings screen), with a Done/✕ that dismisses back to Spaces.
Future<void> showWeatherDetailSheet(BuildContext context, {WeatherInfo? weather}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _WeatherDetailSheet(weather: weather),
  );
}

class _WeatherDetailSheet extends StatelessWidget {
  final WeatherInfo? weather;

  const _WeatherDetailSheet({this.weather});

  String _locationLabel() {
    final prefs = LocationPreferences.instance;
    if (prefs.useGps.value) return 'Using your current location';
    return prefs.manualLabel.value ?? 'Manual location';
  }

  Future<void> _push(BuildContext context, Widget screen) {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weather = this.weather;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Weather',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (weather != null) ...[
              ValueListenableBuilder<bool>(
                valueListenable: UnitPreferences.instance.useMetric,
                builder: (context, useMetric, _) {
                  final temp = useMetric ? weather.tempCelsius : weather.tempFahrenheit;
                  final unit = useMetric ? '°C' : '°F';
                  return Row(
                    children: [
                      Icon(weatherIconData(weather.iconCode), color: scheme.primary, size: 56),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${temp.round()}$unit',
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            weather.condition,
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _locationLabel(),
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.location_off_outlined, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Weather isn't available yet. Set a location to see local "
                        'conditions for your plants.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Divider(height: 1),
            ListTile(
              contentPadding: const EdgeInsets.only(right: 4),
              leading: const Icon(Icons.my_location),
              title: Text(weather == null ? 'Set a location' : 'Change location'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _push(context, const LocationPickerScreen()),
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(right: 4),
              leading: const Icon(Icons.tune),
              title: const Text('Weather settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _push(context, const WeatherSettingsScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
