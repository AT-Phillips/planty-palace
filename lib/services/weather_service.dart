import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
}

/// Fetches current local weather from OpenWeatherMap using the device's GPS
/// location, for plant-care context. Purely additive - any failure (denied
/// permission, no signal, network error, missing API key) returns null and
/// the caller just hides the weather card, never shows an error.
class WeatherService {
  static const _apiKey = String.fromEnvironment('OPENWEATHER_API_KEY');
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherInfo?> fetchCurrentWeather() async {
    if (_apiKey.isEmpty) return null;

    try {
      final position = await _getCurrentPosition();
      if (position == null) return null;

      final uri = Uri.parse(
        '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}'
        '&appid=$_apiKey&units=metric',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final main = data['main'] as Map<String, dynamic>?;
      final weatherList = data['weather'] as List?;
      if (main == null || weatherList == null || weatherList.isEmpty) return null;

      final weather = weatherList.first as Map<String, dynamic>;
      return WeatherInfo(
        tempCelsius: (main['temp'] as num).toDouble(),
        condition: (weather['main'] as String?) ?? '',
        iconCode: (weather['icon'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
    } catch (_) {
      return null;
    }
  }
}
