import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds and persists whether weather should use the device's live GPS
/// location or a manually chosen city. Mirrors [ThemeController]'s pattern.
class LocationPreferences {
  static final LocationPreferences instance = LocationPreferences._internal();
  LocationPreferences._internal();

  static const _useGpsKey = 'locationUseGps';
  static const _manualLatKey = 'locationManualLat';
  static const _manualLonKey = 'locationManualLon';
  static const _manualLabelKey = 'locationManualLabel';

  final ValueNotifier<bool> useGps = ValueNotifier(true);
  final ValueNotifier<double?> manualLat = ValueNotifier(null);
  final ValueNotifier<double?> manualLon = ValueNotifier(null);
  final ValueNotifier<String?> manualLabel = ValueNotifier(null);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    useGps.value = prefs.getBool(_useGpsKey) ?? true;
    manualLat.value = prefs.getDouble(_manualLatKey);
    manualLon.value = prefs.getDouble(_manualLonKey);
    manualLabel.value = prefs.getString(_manualLabelKey);
  }

  Future<void> useDeviceLocation() async {
    useGps.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useGpsKey, true);
  }

  Future<void> setManualLocation({
    required double lat,
    required double lon,
    required String label,
  }) async {
    useGps.value = false;
    manualLat.value = lat;
    manualLon.value = lon;
    manualLabel.value = label;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useGpsKey, false);
    await prefs.setDouble(_manualLatKey, lat);
    await prefs.setDouble(_manualLonKey, lon);
    await prefs.setString(_manualLabelKey, label);
  }
}
