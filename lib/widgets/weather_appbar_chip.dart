import 'package:flutter/material.dart';

import '../services/unit_preferences.dart';
import '../services/weather_preferences.dart';
import '../services/weather_service.dart';
import 'weather_detail_sheet.dart';

/// Compact current-conditions chip for the leading slot of the 4 persistent
/// tabs' app bars (Spaces/Care/Find/Guides - wherever AccountButton already
/// sits on the trailing side). Tapping it opens the same weather detail
/// sheet the old Spaces-only tile used to. Reads from the shared
/// [WeatherStore] rather than fetching its own copy, since all 4 tabs are
/// mounted at once via IndexedStack.
class WeatherAppBarChip extends StatefulWidget {
  const WeatherAppBarChip({super.key});

  @override
  State<WeatherAppBarChip> createState() => _WeatherAppBarChipState();
}

class _WeatherAppBarChipState extends State<WeatherAppBarChip> {
  @override
  void initState() {
    super.initState();
    WeatherStore.instance.ensureLoaded();
  }

  Future<void> _openSheet() async {
    await showWeatherDetailSheet(
      context,
      weather: WeatherStore.instance.weather.value,
    );
    if (mounted) WeatherStore.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: WeatherPreferences.instance.enabled,
      builder: (context, enabled, _) {
        if (!enabled) return const SizedBox.shrink();

        return ValueListenableBuilder<bool>(
          valueListenable: WeatherStore.instance.loading,
          builder: (context, loading, _) {
            return ValueListenableBuilder<WeatherInfo?>(
              valueListenable: WeatherStore.instance.weather,
              builder: (context, weather, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable: UnitPreferences.instance.useMetric,
                  builder: (context, useMetric, _) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: InkWell(
                        onTap: _openSheet,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child:
                              weather == null
                                  ? Icon(
                                    loading
                                        ? Icons.cloud_outlined
                                        : Icons.location_off_outlined,
                                    size: 20,
                                    color: scheme.onSurfaceVariant,
                                  )
                                  : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        weatherIconData(weather.iconCode),
                                        size: 20,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(useMetric ? weather.tempCelsius : weather.tempFahrenheit).round()}°',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
