import 'dart:convert';

import 'package:http/http.dart' as http;

class WikimediaImage {
  final String url;
  final String? attribution;

  WikimediaImage({required this.url, this.attribution});
}

/// Falls back to a Wikimedia Commons photo when Perenual has none for a
/// species - common houseplants (Monstera, pothos, etc.) have much better
/// coverage there than in Perenual's free-tier database. Fully public API,
/// no key needed. Commons images carry specific licenses (public domain,
/// CC-BY, CC-BY-SA) that require attribution, so this also extracts an
/// attribution string for display - never just silently reuse the image.
class WikimediaImageService {
  static const _baseUrl = 'https://commons.wikimedia.org/w/api.php';

  Future<WikimediaImage?> fetchImage(String query) async {
    if (query.trim().isEmpty) return null;

    final result = await _searchOnce(query);
    if (result != null) return result;

    // Obscure cultivars ("Acer palmatum 'Gwen's Rose Delight'") often have no
    // Commons photo of their own - fall back to the base genus + species so a
    // representative photo of the species shows instead of a bare placeholder.
    final base = _baseSpecies(query);
    if (base != null && base != query.trim()) {
      return _searchOnce(base);
    }
    return null;
  }

  /// The base name from a fuller one, dropping cultivar quotes and any
  /// parenthetical, keeping the leading genus (+ species if present) - e.g.
  /// "Acer palmatum 'Gwen's Rose Delight'" -> "Acer palmatum", and
  /// "Malus 'Candied Apple'" -> "Malus". Null if nothing is left.
  String? _baseSpecies(String query) {
    final cleaned = query
        .replaceAll(RegExp(r"['‘’“”].*$"), '')
        .replaceAll(RegExp(r'\(.*\)'), '')
        .trim();
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return null;
    return words.take(2).join(' ');
  }

  Future<WikimediaImage?> _searchOnce(String query) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?action=query&generator=search'
        '&gsrsearch=${Uri.encodeQueryComponent(query)}&gsrnamespace=6&gsrlimit=1'
        '&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=500'
        '&format=json&origin=*',
      );

      // One short retry on transient failures before giving up.
      http.Response? response;
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          response = await http.get(uri);
          if (response.statusCode == 200) break;
        } catch (_) {
          if (attempt == 1) rethrow;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      if (response == null || response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final pages = data['query']?['pages'] as Map<String, dynamic>?;
      if (pages == null || pages.isEmpty) return null;

      final page = pages.values.first as Map<String, dynamic>;
      final imageInfoList = page['imageinfo'] as List?;
      if (imageInfoList == null || imageInfoList.isEmpty) return null;

      final info = imageInfoList.first as Map<String, dynamic>;
      final url = info['thumburl'] as String? ?? info['url'] as String?;
      if (url == null) return null;

      final extmetadata = info['extmetadata'] as Map<String, dynamic>?;
      final artist = _stripHtml(extmetadata?['Artist']?['value'] as String?);
      final license = extmetadata?['LicenseShortName']?['value'] as String?;
      final attributionParts = [
        if (artist != null && artist.isNotEmpty) artist,
        if (license != null && license.isNotEmpty) license,
      ];

      return WikimediaImage(
        url: url,
        attribution: attributionParts.isEmpty ? null : attributionParts.join(' · '),
      );
    } catch (_) {
      return null;
    }
  }

  String? _stripHtml(String? value) {
    if (value == null) return null;
    return value.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
