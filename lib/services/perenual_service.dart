import 'dart:convert';
import 'package:http/http.dart' as http;

class PerenualCareInfo {
  final int? wateringIntervalDays;
  final String careInstructions;

  PerenualCareInfo({required this.wateringIntervalDays, required this.careInstructions});
}

class PerenualSpeciesSummary {
  final int id;
  final String scientificName;
  final String? commonName;
  final String? thumbnailUrl;

  PerenualSpeciesSummary({
    required this.id,
    required this.scientificName,
    this.commonName,
    this.thumbnailUrl,
  });
}

/// Fuller species info for the Discover catalog - everything in
/// [PerenualCareInfo] plus genuinely sourced reference facts. Every extra
/// field is nullable/omitted if Perenual didn't return it for that species -
/// never fabricated content presented as fact.
class PerenualSpeciesDetail {
  final String scientificName;
  final String? commonName;
  final String? imageUrl;
  final int? wateringIntervalDays;
  final String careInstructions;
  final String? description;
  final String? origin;
  final String? family;
  final bool? poisonousToHumans;
  final bool? poisonousToPets;

  PerenualSpeciesDetail({
    required this.scientificName,
    this.commonName,
    this.imageUrl,
    required this.wateringIntervalDays,
    required this.careInstructions,
    this.description,
    this.origin,
    this.family,
    this.poisonousToHumans,
    this.poisonousToPets,
  });
}

/// Looks up plant-care data (watering frequency, sunlight, care level) and
/// reference facts from the Perenual species database. Purely additive
/// enrichment - any failure or "no match" is treated as no data, never an
/// error the user has to deal with.
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
      final detail = await fetchSpeciesDetail(id);
      if (detail == null) return null;
      return PerenualCareInfo(
        wateringIntervalDays: detail.wateringIntervalDays,
        careInstructions: detail.careInstructions,
      );
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

  /// Returns several candidate species matching [query], for the Discover
  /// catalog's live search - not just the single best match.
  ///
  /// Unlike [lookupCareInfo] (purely additive enrichment, safe to swallow
  /// failures), this throws on failure instead of silently returning an
  /// empty list - Discover's search is the primary content of that screen,
  /// so a misconfigured API key or an exhausted Perenual quota needs to be
  /// visibly distinguishable from "no species actually matched."
  Future<List<PerenualSpeciesSummary>> searchSpecies(String query) async {
    if (query.trim().isEmpty) return [];
    if (_apiKey.isEmpty) {
      throw Exception('No Perenual API key configured for this build.');
    }

    final uri = Uri.parse(
      '$_baseUrl/species-list?key=$_apiKey&q=${Uri.encodeQueryComponent(query)}',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Perenual returned ${response.statusCode}: ${response.body}');
    }

    final data = json.decode(response.body);
    final results = data['data'] as List?;
    if (results == null) return [];

    return results.map((entry) {
      final map = entry as Map<String, dynamic>;
      final commonNames = map['common_name'] as String?;
      final image = map['default_image'] as Map<String, dynamic>?;
      return PerenualSpeciesSummary(
        id: map['id'] as int,
        scientificName: (map['scientific_name'] as List?)?.first?.toString() ??
            commonNames ??
            'Unknown species',
        commonName: commonNames,
        thumbnailUrl: image?['thumbnail'] as String? ?? image?['small_url'] as String?,
      );
    }).toList();
  }

  Future<PerenualSpeciesDetail?> fetchSpeciesDetail(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/species/details/$id?key=$_apiKey');
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;

      final watering = (data['watering'] as String?)?.toLowerCase();
      final wateringIntervalDays = watering != null ? _wateringToDays[watering] : null;

      final sunlight = data['sunlight'];
      final sunlightText = sunlight is List ? sunlight.join(', ') : sunlight?.toString();
      final careLevel = data['care_level'] as String?;

      final careParts = <String>[
        if (data['watering'] != null) 'Watering: ${data['watering']}',
        if (sunlightText != null && sunlightText.isNotEmpty) 'Sunlight: $sunlightText',
        if (careLevel != null) 'Care level: $careLevel',
      ];

      final origin = data['origin'];
      final originText = origin is List ? origin.join(', ') : origin?.toString();
      final image = data['default_image'] as Map<String, dynamic>?;
      final scientificName = (data['scientific_name'] as List?)?.first?.toString() ??
          data['common_name'] as String? ??
          'Unknown species';

      return PerenualSpeciesDetail(
        scientificName: scientificName,
        commonName: data['common_name'] as String?,
        imageUrl: image?['regular_url'] as String? ?? image?['medium_url'] as String?,
        wateringIntervalDays: wateringIntervalDays,
        careInstructions: careParts.join('\n'),
        description: (data['description'] as String?)?.trim().isNotEmpty == true
            ? data['description'] as String
            : null,
        origin: (originText != null && originText.isNotEmpty) ? originText : null,
        family: data['family'] as String?,
        poisonousToHumans: _asBool(data['poisonous_to_humans']),
        poisonousToPets: _asBool(data['poisonous_to_pets']),
      );
    } catch (_) {
      return null;
    }
  }

  bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    return null;
  }
}
