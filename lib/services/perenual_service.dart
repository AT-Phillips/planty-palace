import 'package:cloud_functions/cloud_functions.dart';

class PerenualCareInfo {
  final int? wateringIntervalDays;
  final String careInstructions;

  // The rest of what Perenual returned for this species, carried through so
  // AddEditPlantScreen can store it on the Plant itself rather than
  // discarding it - see PerenualSpeciesDetail for field provenance.
  final String? description;
  final String? origin;
  final String? family;
  final String? imageUrl;
  final bool? poisonousToHumans;
  final bool? poisonousToPets;

  PerenualCareInfo({
    required this.wateringIntervalDays,
    required this.careInstructions,
    this.description,
    this.origin,
    this.family,
    this.imageUrl,
    this.poisonousToHumans,
    this.poisonousToPets,
  });
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

  factory PerenualSpeciesSummary.fromMap(Map<String, dynamic> map) {
    return PerenualSpeciesSummary(
      id: map['id'] as int,
      scientificName: map['scientificName'] as String,
      commonName: map['commonName'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
    );
  }
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

  factory PerenualSpeciesDetail.fromMap(Map<String, dynamic> map) {
    return PerenualSpeciesDetail(
      scientificName: map['scientificName'] as String,
      commonName: map['commonName'] as String?,
      imageUrl: map['imageUrl'] as String?,
      wateringIntervalDays: map['wateringIntervalDays'] as int?,
      careInstructions: map['careInstructions'] as String? ?? '',
      description: map['description'] as String?,
      origin: map['origin'] as String?,
      family: map['family'] as String?,
      poisonousToHumans: map['poisonousToHumans'] as bool?,
      poisonousToPets: map['poisonousToPets'] as bool?,
    );
  }
}

/// Looks up plant-care data and reference facts from the Perenual species
/// database - via Cloud Functions (`searchSpecies`/`fetchSpeciesDetail`),
/// which hold the real API key server-side and serve a shared Firestore
/// cache, rather than calling Perenual directly with a key embedded in the
/// client. See functions/src/perenual.ts.
class PerenualService {
  // Resolved lazily rather than at construction so simply creating the
  // service (e.g. when its screen mounts) never touches Firebase before
  // it's initialized.
  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  /// Purely additive enrichment - any failure or "no match" is treated as
  /// no data, never an error the user has to deal with.
  Future<PerenualCareInfo?> lookupCareInfo(String speciesName) async {
    try {
      final matches = await searchSpecies(speciesName);
      if (matches.isEmpty) return null;
      final detail = await fetchSpeciesDetail(matches.first.id);
      if (detail == null) return null;
      return PerenualCareInfo(
        wateringIntervalDays: detail.wateringIntervalDays,
        careInstructions: detail.careInstructions,
        description: detail.description,
        origin: detail.origin,
        family: detail.family,
        imageUrl: detail.imageUrl,
        poisonousToHumans: detail.poisonousToHumans,
        poisonousToPets: detail.poisonousToPets,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns several candidate species matching [query], for the Discover
  /// catalog's live search - not just the single best match.
  ///
  /// Unlike [lookupCareInfo] (purely additive enrichment, safe to swallow
  /// failures), this throws on failure instead of silently returning an
  /// empty list - Discover's search is the primary content of that screen,
  /// so a real failure needs to be visibly distinguishable from "no species
  /// actually matched."
  Future<List<PerenualSpeciesSummary>> searchSpecies(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final result = await _functions.httpsCallable('searchSpecies').call({
        'query': query,
      });
      final data = result.data as List;
      return data
          .map(
            (entry) => PerenualSpeciesSummary.fromMap(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList();
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Species search failed.');
    }
  }

  Future<PerenualSpeciesDetail?> fetchSpeciesDetail(int id) async {
    try {
      final result = await _functions.httpsCallable('fetchSpeciesDetail').call({
        'id': id,
      });
      return PerenualSpeciesDetail.fromMap(
        Map<String, dynamic>.from(result.data as Map),
      );
    } catch (_) {
      return null;
    }
  }
}
