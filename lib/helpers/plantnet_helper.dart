import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

class PlantNetHelper {
  static Future<Map<String, dynamic>?> identifyPlant({
    required List<File> images,
    String organ = 'leaf',
  }) async {
    if (images.isEmpty) {
      print('No images provided for identification.');
      return null;
    }

    final apiKey = '2b10mnVd9ujJUMfN0dm88OCT2';  // Replace with your PlantNet API key
    final url = Uri.parse(
      'https://my-api.plantnet.org/v2/identify/all?api-key=$apiKey',
    );

    final request = http.MultipartRequest('POST', url);

    for (final imageFile in images) {
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      try {
        request.files.add(await http.MultipartFile.fromPath(
          'images',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
          filename: basename(imageFile.path),
        ));
      } catch (e) {
        print('Error adding image file "${imageFile.path}": $e');
        // You can choose to continue or return null here
        return null;
      }
    }

    request.fields['organs'] = List.filled(images.length, organ).join(',');

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      } else {
        print('PlantNet identification failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error identifying plant: $e');
      return null;
    }
  }
}
