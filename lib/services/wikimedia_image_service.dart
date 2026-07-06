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

    try {
      final uri = Uri.parse(
        '$_baseUrl?action=query&generator=search'
        '&gsrsearch=${Uri.encodeQueryComponent(query)}&gsrnamespace=6&gsrlimit=1'
        '&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=500'
        '&format=json&origin=*',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

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
