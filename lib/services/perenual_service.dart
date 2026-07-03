import 'dart:convert';
import 'package:http/http.dart' as http;

class PerenualCareInfo {
  final int? wateringIntervalDays;
  final String careInstructions;

  PerenualCareInfo({required this.wateringIntervalDays, required this.careInstructions});
}

/// Looks up plant-care data (watering frequency, sunlight, care level) from
/// the Perenual species database, to enrich a plant once PlantNet has
/// identified its species. Purely additive enrichment — any failure or "no
/// match" is treated as no data, never an error the user has to deal with.
class PerenualService {
  static const _apiKey = String.fromEnvironment('PERENUAL_API_KEY');
  static const _baseUrl = 'https://perenual.com/api/v2';

  static const Map<String, int> _wateringToDays = {
    'frequent': 3,
    'average': 7,
    'minimum': 14,
    'none': 30,
  };

  Future<PerenualCareInfo?> lookupCareInfo(String speciesName) async {
    if (_apiKey.isEmpty) return null;

    try {
      final id = await _findSpeciesId(speciesName);
      if (id == null) return null;
      return await _fetchCareInfo(id);
    } catch (_) {
      return null;
    }
  }

  Future<int?> _findSpeciesId(String speciesName) async {
    final uri = Uri.parse(
      '$_baseUrl/species-list?key=$_apiKey&q=${Uri.encodeQueryComponent(speciesName)}',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    final results = data['data'] as List?;
    if (results == null || results.isEmpty) return null;

    return results.first['id'] as int?;
  }

  Future<PerenualCareInfo?> _fetchCareInfo(int id) async {
    final uri = Uri.parse('$_baseUrl/species/details/$id?key=$_apiKey');
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map<String, dynamic>;

    final watering = (data['watering'] as String?)?.toLowerCase();
    final wateringIntervalDays = watering != null ? _wateringToDays[watering] : null;

    final sunlight = data['sunlight'];
    final sunlightText = sunlight is List ? sunlight.join(', ') : sunlight?.toString();
    final careLevel = data['care_level'] as String?;

    final parts = <String>[
      if (data['watering'] != null) 'Watering: ${data['watering']}',
      if (sunlightText != null && sunlightText.isNotEmpty) 'Sunlight: $sunlightText',
      if (careLevel != null) 'Care level: $careLevel',
    ];

    return PerenualCareInfo(
      wateringIntervalDays: wateringIntervalDays,
      careInstructions: parts.join('\n'),
    );
  }
}
