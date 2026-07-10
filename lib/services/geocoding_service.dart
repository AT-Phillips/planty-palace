import 'package:cloud_functions/cloud_functions.dart';

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

  factory GeocodingResult.fromMap(Map<String, dynamic> map) {
    return GeocodingResult(
      name: map['name'] as String? ?? '',
      state: map['state'] as String?,
      country: map['country'] as String? ?? '',
      lat: (map['lat'] as num).toDouble(),
      lon: (map['lon'] as num).toDouble(),
    );
  }
}

/// Turns a typed city name into a short list of location candidates, via
/// the `geocodeCity` Cloud Function (see functions/src/weather.ts), which
/// shares the same server-held OpenWeatherMap key as [WeatherService] and
/// caches results (city coordinates are effectively static). Any failure
/// just returns an empty list - the caller shows "no results" rather than
/// an error.
class GeocodingService {
  Future<List<GeocodingResult>> searchCity(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('geocodeCity')
          .call({'query': query});
      final data = result.data as List;
      return data
          .map(
            (entry) =>
                GeocodingResult.fromMap(Map<String, dynamic>.from(entry)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}
