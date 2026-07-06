import 'package:flutter/material.dart';

import '../services/location_preferences.dart';
import '../services/unit_preferences.dart';
import '../services/weather_preferences.dart';
import '../widgets/frosted_app_bar.dart';
import 'location_picker_screen.dart';

/// Unit system, location, and weather-visibility controls, split out from
/// the former inline weather-related rows in SettingsSections into their
/// own screen - see LocationPickerScreen for the pattern this follows.
class WeatherSettingsScreen extends StatefulWidget {
  const WeatherSettingsScreen({super.key});

  @override
  State<WeatherSettingsScreen> createState() => _WeatherSettingsScreenState();
}

class _WeatherSettingsScreenState extends State<WeatherSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FrostedAppBar(title: 'Weather'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: UnitPreferences.instance.useMetric,
                  builder: (context, useMetric, _) {
                    return ListTile(
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
                      onTap: () => UnitPreferences.instance.setUseMetric(!useMetric),
                    );
                  },
                ),
                const Divider(height: 1),
                ValueListenableBuilder<bool>(
                  valueListenable: LocationPreferences.instance.useGps,
                  builder: (context, useGps, _) {
                    return ValueListenableBuilder<String?>(
                      valueListenable: LocationPreferences.instance.manualLabel,
                      builder: (context, manualLabel, _) {
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(
                            useGps ? 'Using device location' : (manualLabel ?? 'Manual location'),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                          ),
                        );
                      },
                    );
                  },
                ),
                const Divider(height: 1),
                ValueListenableBuilder<bool>(
                  valueListenable: WeatherPreferences.instance.enabled,
                  builder: (context, enabled, _) {
                    return SwitchListTile(
                      secondary: const Icon(Icons.wb_sunny_outlined),
                      title: const Text('Show local weather'),
                      subtitle: const Text('Displayed at the top of My Spaces'),
                      value: enabled,
                      onChanged: (value) => WeatherPreferences.instance.setEnabled(value),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
