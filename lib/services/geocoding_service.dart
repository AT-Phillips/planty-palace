import 'dart:convert';

import 'package:http/http.dart' as http;

class GeocodingResult {
  final String name;
  final String? state;
  final String country;
  final double lat;
  final double lon;

  GeocodingResult({
    required this.name,
    this.state,
    required this.country,
    required this.lat,
    required this.lon,
  });

  String get displayLabel =>
      [name, if (state != null && state!.isNotEmpty) state, country].join(', ');
}

/// Turns a typed city name into a short list of location candidates, using
/// the same OpenWeatherMap API key already used by [WeatherService] (no
/// separate key/service needed). Any failure just returns an empty list -
/// the caller shows "no results" rather than an error.
class GeocodingService {
  static const _apiKey = String.fromEnvironment('OPENWEATHER_API_KEY');
  static const _baseUrl = 'https://api.openweathermap.org/geo/1.0/direct';

  Future<List<GeocodingResult>> searchCity(String query) async {
    if (_apiKey.isEmpty || query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(query)}&limit=5&appid=$_apiKey');
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as List;
      return data.map((entry) {
        final map = entry as Map<String, dynamic>;
        return GeocodingResult(
          name: map['name'] as String? ?? '',
          state: map['state'] as String?,
          country: map['country'] as String? ?? '',
          lat: (map['lat'] as num).toDouble(),
          lon: (map['lon'] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
