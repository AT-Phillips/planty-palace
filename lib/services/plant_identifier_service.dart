import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

class PlantIdentifierService {
  static const _apiKey = String.fromEnvironment('PLANTNET_API_KEY');

  final ImagePicker _picker = ImagePicker();

  File? imageFile;
  String organ = 'leaf'; // default

  Future<void> pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
    }
  }

  Future<void> pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
    }
  }

  /// Discards the currently picked image, deleting it from disk if it exists.
  Future<void> clearImage() async {
    final file = imageFile;
    imageFile = null;
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  Future<List<String>> identifyPlant() async {
    final file = imageFile;
    if (file == null) return [];

    if (_apiKey.isEmpty) {
      throw Exception(
        'Missing PlantNet API key. Run with --dart-define=PLANTNET_API_KEY=<key>.',
      );
    }

    final uri = Uri.parse(
      'https://my-api.plantnet.org/v2/identify/all?api-key=$_apiKey',
    );
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';

    final request = http.MultipartRequest('POST', uri)
      ..fields['organs'] = organ
      ..files.add(await http.MultipartFile.fromPath(
        'images',
        file.path,
        contentType: MediaType.parse(mimeType),
        filename: basename(file.path),
      ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      final results = data['results'] as List;
      return results
          .map((r) => r['species']['scientificNameWithoutAuthor'].toString())
          .toList();
    } else {
      throw Exception('Failed to identify plant: ${response.statusCode}');
    }
  }
}
