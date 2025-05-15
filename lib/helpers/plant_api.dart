import 'dart:convert';
import 'package:http/http.dart' as http;

class PlantApi {
  static const _baseUrl = 'https://trefle.io/api/v1/plants/search';
  static const _token = 'YOUR_TREFLE_API_KEY_HERE'; // replace this

  // Get plant name suggestions by query string
  static Future<List<String>> fetchPlantNames(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse('$_baseUrl?token=$_token&q=$query');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['data'] as List<dynamic>;

      // Extract unique plant common names for suggestions
      final names = <String>{};
      for (var plant in results) {
        final commonName = plant['common_name'];
        if (commonName != null) {
          names.add(commonName);
        }
      }
      return names.toList();
    } else {
      throw Exception('Failed to fetch plant names');
    }
  }
}
