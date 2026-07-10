import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'perenual_service.dart';

class RecentSpecies {
  final PerenualSpeciesSummary summary;
  final PerenualSpeciesDetail detail;

  RecentSpecies({required this.summary, required this.detail});
}

/// Remembers the last several species a user has actually opened, purely
/// on-device (shared_preferences) - powers both the "recently viewed" list
/// in Find (so returning to a plant doesn't need a fresh search) and an
/// offline fallback when a live fetchSpeciesDetail call fails, since
/// content someone already viewed once is still useful without a network.
class SpeciesCacheService {
  SpeciesCacheService._();
  static final instance = SpeciesCacheService._();

  static const _prefsKey = 'recent_species_v1';
  static const _maxEntries = 30;

  Future<void> recordViewed(
    PerenualSpeciesSummary summary,
    PerenualSpeciesDetail detail,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _decode(prefs.getStringList(_prefsKey));
    entries.removeWhere((e) => (e['summary'] as Map)['id'] == summary.id);
    entries.insert(0, {
      'summary': _summaryToMap(summary),
      'detail': _detailToMap(detail),
    });
    if (entries.length > _maxEntries) {
      entries.removeRange(_maxEntries, entries.length);
    }
    await prefs.setStringList(_prefsKey, entries.map(jsonEncode).toList());
  }

  Future<List<RecentSpecies>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getStringList(_prefsKey)).map((entry) {
      return RecentSpecies(
        summary: PerenualSpeciesSummary.fromMap(
          Map<String, dynamic>.from(entry['summary'] as Map),
        ),
        detail: PerenualSpeciesDetail.fromMap(
          Map<String, dynamic>.from(entry['detail'] as Map),
        ),
      );
    }).toList();
  }

  /// Offline/failure fallback - null if this species was never viewed
  /// before on this device.
  Future<PerenualSpeciesDetail?> getCachedDetail(int id) async {
    for (final entry in await getRecent()) {
      if (entry.summary.id == id) return entry.detail;
    }
    return null;
  }

  List<Map<String, dynamic>> _decode(List<String>? raw) {
    if (raw == null) return [];
    return raw
        .map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map))
        .toList();
  }

  Map<String, dynamic> _summaryToMap(PerenualSpeciesSummary s) => {
    'id': s.id,
    'scientificName': s.scientificName,
    'commonName': s.commonName,
    'thumbnailUrl': s.thumbnailUrl,
  };

  Map<String, dynamic> _detailToMap(PerenualSpeciesDetail d) => {
    'scientificName': d.scientificName,
    'commonName': d.commonName,
    'imageUrl': d.imageUrl,
    'wateringIntervalDays': d.wateringIntervalDays,
    'careInstructions': d.careInstructions,
    'description': d.description,
    'origin': d.origin,
    'family': d.family,
    'poisonousToHumans': d.poisonousToHumans,
    'poisonousToPets': d.poisonousToPets,
  };
}
