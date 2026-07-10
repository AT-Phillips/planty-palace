import 'package:flutter/material.dart';

import '../services/geocoding_service.dart';
import '../services/location_preferences.dart';
import '../services/unit_preferences.dart';
import '../services/weather_preferences.dart';
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

/// Pops up local weather as a bottom sheet - the single surface for every
/// weather-related control (current conditions, units, location, and the
/// show/hide toggle), instead of navigating to separate screens.
Future<void> showWeatherDetailSheet(
  BuildContext context, {
  WeatherInfo? weather,
}) {
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

class _WeatherDetailSheet extends StatefulWidget {
  final WeatherInfo? weather;

  const _WeatherDetailSheet({this.weather});

  @override
  State<_WeatherDetailSheet> createState() => _WeatherDetailSheetState();
}

class _WeatherDetailSheetState extends State<_WeatherDetailSheet> {
  final _cityController = TextEditingController();
  final _geocoding = GeocodingService();
  List<GeocodingResult> _results = [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _searchCity() async {
    final query = _cityController.text.trim();
    if (query.isEmpty) return;

    setState(() => _searching = true);
    final results = await _geocoding.searchCity(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
      _searched = true;
    });
  }

  Future<void> _selectResult(GeocodingResult result) async {
    await LocationPreferences.instance.setManualLocation(
      lat: result.lat,
      lon: result.lon,
      label: result.displayLabel,
    );
    if (!mounted) return;
    setState(() {
      _results = [];
      _searched = false;
      _cityController.clear();
    });
  }

  Future<void> _useDeviceLocation() async {
    await LocationPreferences.instance.useDeviceLocation();
  }

  String _locationLabel() {
    final prefs = LocationPreferences.instance;
    if (prefs.useGps.value) return 'Using your current location';
    return prefs.manualLabel.value ?? 'Manual location';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weather = widget.weather;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                    final temp =
                        useMetric
                            ? weather.tempCelsius
                            : weather.tempFahrenheit;
                    final unit = useMetric ? '°C' : '°F';
                    return Row(
                      children: [
                        Icon(
                          weatherIconData(weather.iconCode),
                          color: scheme.primary,
                          size: 56,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${temp.round()}$unit',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              weather.condition,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
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
                  child: ValueListenableBuilder<bool>(
                    valueListenable: LocationPreferences.instance.useGps,
                    builder:
                        (context, useGps, _) => ValueListenableBuilder<String?>(
                          valueListenable:
                              LocationPreferences.instance.manualLabel,
                          builder:
                              (context, manualLabel, _) => Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _locationLabel(),
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        ),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 4, bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Weather isn't available yet. Set a location below to see "
                          'local conditions for your plants.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                'Location',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _useDeviceLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Use my current location'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchCity(),
                      decoration: const InputDecoration(
                        hintText: 'Or search for a city',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _searching ? null : _searchCity,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
              if (_searching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
              if (!_searching && _searched && _results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No matching cities found.'),
                ),
              for (final result in _results)
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(result.displayLabel),
                    onTap: () => _selectResult(result),
                  ),
                ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              ValueListenableBuilder<bool>(
                valueListenable: UnitPreferences.instance.useMetric,
                builder: (context, useMetric, _) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(right: 4),
                    leading: const Icon(Icons.straighten_outlined),
                    title: const Text('Unit System'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          useMetric ? 'Metric' : 'Imperial',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap:
                        () => UnitPreferences.instance.setUseMetric(!useMetric),
                  );
                },
              ),
              const Divider(height: 1),
              ValueListenableBuilder<bool>(
                valueListenable: WeatherPreferences.instance.enabled,
                builder: (context, enabled, _) {
                  return SwitchListTile(
                    contentPadding: const EdgeInsets.only(right: 4),
                    secondary: const Icon(Icons.wb_sunny_outlined),
                    title: const Text('Show local weather'),
                    subtitle: const Text('Displayed at the top of Spaces'),
                    value: enabled,
                    onChanged:
                        (value) =>
                            WeatherPreferences.instance.setEnabled(value),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
