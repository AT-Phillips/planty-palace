import 'package:flutter/material.dart';

import '../services/geocoding_service.dart';
import '../services/location_preferences.dart';
import '../widgets/frosted_app_bar.dart';

/// Lets the user pick where weather (and any future location-aware
/// features) should be based: either the device's live GPS location, or a
/// manually chosen city.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _controller = TextEditingController();
  final _geocoding = GeocodingService();
  List<GeocodingResult> _results = [];
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
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
    if (mounted) Navigator.pop(context);
  }

  Future<void> _useDeviceLocation() async {
    await LocationPreferences.instance.useDeviceLocation();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FrostedAppBar(title: 'Location'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _useDeviceLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Use my current location'),
          ),
          const SizedBox(height: 24),
          Text(
            'Or search for a city',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: const InputDecoration(hintText: 'e.g. Portland'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _searching ? null : _search,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_searching) const Center(child: CircularProgressIndicator.adaptive()),
          if (!_searching && _searched && _results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No matching cities found.'),
            ),
          for (final result in _results)
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(result.displayLabel),
                onTap: () => _selectResult(result),
              ),
            ),
        ],
      ),
    );
  }
}
