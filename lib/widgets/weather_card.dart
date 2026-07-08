import 'package:flutter/material.dart';

import '../services/unit_preferences.dart';
import '../services/weather_preferences.dart';
import '../services/weather_service.dart';
import 'weather_detail_sheet.dart';

/// Shows current local weather (for plant-care context) at the top of the
/// Spaces hub. Tapping it opens a bottom-sheet with more detail and location
/// controls. Hides itself entirely if disabled in Settings or if fetching
/// weather fails for any reason (no permission, no signal, etc).
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final WeatherService _service = WeatherService();

  // MainShell rebuilds each tab fresh on every switch (not an IndexedStack),
  // so this State is recreated every time Spaces is shown - seeding from the
  // last successful fetch avoids a flash of "hidden" while the new fetch is
  // in flight.
  static WeatherInfo? _cachedWeather;

  WeatherInfo? _weather = _cachedWeather;
  bool _loading = _cachedWeather == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final weather = await _service.fetchCurrentWeather();
    _cachedWeather = weather;
    if (!mounted) return;
    setState(() {
      _weather = weather;
      _loading = false;
    });
  }

  /// Opens the weather detail sheet, then reloads - the location or units may
  /// have been changed from inside the sheet.
  Future<void> _openSheet() async {
    await showWeatherDetailSheet(context, weather: _weather);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: WeatherPreferences.instance.enabled,
      builder: (context, enabled, _) {
        if (!enabled || _loading) return const SizedBox.shrink();

        if (_weather == null) {
          final scheme = Theme.of(context).colorScheme;
          return Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: ListTile(
              leading: Icon(Icons.location_off_outlined, color: scheme.onSurfaceVariant),
              title: const Text('Weather unavailable'),
              subtitle: const Text('Tap to set a location'),
              onTap: _openSheet,
            ),
          );
        }

        final scheme = Theme.of(context).colorScheme;
        final weather = _weather!;

        return ValueListenableBuilder<bool>(
          valueListenable: UnitPreferences.instance.useMetric,
          builder: (context, useMetric, _) {
            final temp = useMetric ? weather.tempCelsius : weather.tempFahrenheit;
            final unit = useMetric ? '°C' : '°F';

            return Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openSheet,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(weatherIconData(weather.iconCode), color: scheme.primary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${temp.round()}$unit',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              weather.condition,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
