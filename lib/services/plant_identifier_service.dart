import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PlantIdentifierService {
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

  void toggleOrgan() {
    organ = (organ == 'leaf') ? 'flower' : 'leaf';
  }

  Future<List<String>> identifyPlant() async {
    if (imageFile == null) return [];

    final uri = Uri.parse('https://my-api.plantnet.org/v2/identify/all?api-key=YOUR_API_KEY');
    final request = http.MultipartRequest('POST', uri)
      ..fields['organs'] = organ
      ..files.add(await http.MultipartFile.fromPath('images', imageFile!.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      final results = data['results'] as List;
      return results
          .map((r) => r['species']['scientificNameWithoutAuthor'].toString())
          .toList();
    } else {
      throw Exception('Failed to identify plant');
    }
  }
}
