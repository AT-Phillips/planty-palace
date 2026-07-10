import 'package:cloud_functions/cloud_functions.dart';

class PestDiseaseInfo {
  final int id;
  final String commonName;
  final String? scientificName;
  final String? family;
  final String? description;
  final String? solution;
  final List<String> hostPlants;
  final String? imageUrl;

  PestDiseaseInfo({
    required this.id,
    required this.commonName,
    this.scientificName,
    this.family,
    this.description,
    this.solution,
    required this.hostPlants,
    this.imageUrl,
  });

  factory PestDiseaseInfo.fromMap(Map<String, dynamic> map) {
    return PestDiseaseInfo(
      id: map['id'] as int,
      commonName: map['commonName'] as String? ?? 'Unknown problem',
      scientificName: map['scientificName'] as String?,
      family: map['family'] as String?,
      description: map['description'] as String?,
      solution: map['solution'] as String?,
      hostPlants:
          (map['hostPlants'] as List?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: map['imageUrl'] as String?,
    );
  }
}

/// Looks up common pest/disease reference info from Perenual's
/// pest-disease-list - via the `searchPestsDiseases` Cloud Function, which
/// shares the same server-side API key and Firestore cache pattern as
/// [PerenualService]. See functions/src/pests.ts.
class PestDiseaseService {
  // Resolved lazily rather than at construction so simply creating the
  // service never touches Firebase before it's initialized.
  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  Future<List<PestDiseaseInfo>> search(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final result = await _functions.httpsCallable('searchPestsDiseases').call(
        {'query': query},
      );
      final data = result.data as List;
      return data
          .map(
            (entry) =>
                PestDiseaseInfo.fromMap(Map<String, dynamic>.from(entry)),
          )
          .toList();
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Pest/disease search failed.');
    }
  }
}
