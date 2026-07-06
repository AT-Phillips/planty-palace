import 'package:flutter/material.dart';

import '../services/unit_preferences.dart';
import '../services/weather_preferences.dart';
import '../services/weather_service.dart';

IconData _iconFor(String owmIconCode) {
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

/// Shows current local weather (for plant-care context) at the top of My
/// Spaces. Hides itself entirely if disabled in Settings or if fetching
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: WeatherPreferences.instance.enabled,
      builder: (context, enabled, _) {
        if (!enabled || _loading || _weather == null) return const SizedBox.shrink();

        final scheme = Theme.of(context).colorScheme;
        final weather = _weather!;

        return ValueListenableBuilder<bool>(
          valueListenable: UnitPreferences.instance.useMetric,
          builder: (context, useMetric, _) {
            final temp = useMetric ? weather.tempCelsius : weather.tempFahrenheit;
            final unit = useMetric ? '°C' : '°F';

            return Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(_iconFor(weather.iconCode), color: scheme.primary, size: 32),
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
