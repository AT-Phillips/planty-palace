import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'location_preferences.dart';

class WeatherInfo {
  final double tempCelsius;
  final String condition;
  final String iconCode;

  WeatherInfo({
    required this.tempCelsius,
    required this.condition,
    required this.iconCode,
  });

  double get tempFahrenheit => tempCelsius * 9 / 5 + 32;

  factory WeatherInfo.fromMap(Map<String, dynamic> map) {
    return WeatherInfo(
      tempCelsius: (map['tempCelsius'] as num).toDouble(),
      condition: map['condition'] as String? ?? '',
      iconCode: map['iconCode'] as String? ?? '',
    );
  }
}

/// Fetches current local weather for plant-care context, via the
/// `fetchWeather` Cloud Function (see functions/src/weather.ts), which
/// holds the real OpenWeatherMap API key server-side and serves a shared
/// Firestore cache keyed by a coarse location grid - rather than calling
/// OpenWeatherMap directly with a key embedded in the client. Purely
/// additive - any failure (denied permission, no signal, network error)
/// returns null and the caller just hides the weather card, never shows an
/// error.
class WeatherService {
  Future<WeatherInfo?> fetchCurrentWeather() async {
    try {
      final coordinates = await _resolveCoordinates();
      if (coordinates == null) return null;

      final result = await FirebaseFunctions.instance
          .httpsCallable('fetchWeather')
          .call({'lat': coordinates.$1, 'lon': coordinates.$2});
      return WeatherInfo.fromMap(Map<String, dynamic>.from(result.data as Map));
    } catch (_) {
      return null;
    }
  }

  Future<(double, double)?> _resolveCoordinates() async {
    final prefs = LocationPreferences.instance;
    if (!prefs.useGps.value) {
      final lat = prefs.manualLat.value;
      final lon = prefs.manualLon.value;
      if (lat != null && lon != null) return (lat, lon);
    }

    final position = await _getCurrentPosition();
    if (position == null) return null;
    return (position.latitude, position.longitude);
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

/// A single shared current-weather cache + in-flight fetch, so every
/// consumer (the app-bar chip on each of the 4 persistent tabs, the detail
/// sheet) reads one shared result instead of firing its own fetch - matters
/// because MainShell keeps all 4 tabs mounted simultaneously via
/// IndexedStack, so per-widget fetching would mean 4 concurrent network
/// calls on every app open.
class WeatherStore {
  WeatherStore._();
  static final WeatherStore instance = WeatherStore._();

  final WeatherService _service = WeatherService();
  final ValueNotifier<WeatherInfo?> weather = ValueNotifier(null);
  final ValueNotifier<bool> loading = ValueNotifier(true);

  bool _loaded = false;
  Future<void>? _inFlight;

  /// Fetches once and caches; a widget calling this while a fetch is already
  /// in flight (e.g. all 4 tab chips mounting together) awaits the same
  /// future instead of starting a new one.
  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _inFlight ??= _fetch();
  }

  Future<void> refresh() => _inFlight = _fetch();

  Future<void> _fetch() async {
    loading.value = true;
    final result = await _service.fetchCurrentWeather();
    weather.value = result;
    loading.value = false;
    _loaded = true;
    _inFlight = null;
  }
}
