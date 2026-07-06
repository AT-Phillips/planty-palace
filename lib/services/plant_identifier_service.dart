import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_service.dart';

/// One candidate match from an identification request, ranked by [score]
/// (PlantNet's own confidence, 0.0-1.0).
class PlantSuggestion {
  final String scientificName;
  final String? commonName;
  final double score;

  PlantSuggestion({
    required this.scientificName,
    required this.commonName,
    required this.score,
  });

  factory PlantSuggestion.fromMap(Map<String, dynamic> map) {
    return PlantSuggestion(
      scientificName: map['scientificName'] as String,
      commonName: map['commonName'] as String?,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Identifies a plant from a photo via the `identifyPlant` Cloud Function
/// (see functions/src/identify.ts), which holds the real PlantNet API key
/// server-side and enforces a per-user daily cap - rather than calling
/// PlantNet directly with a key embedded in the client.
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

  /// Discards the currently picked image, deleting it from disk if it exists.
  Future<void> clearImage() async {
    final file = imageFile;
    imageFile = null;
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  Future<List<PlantSuggestion>> identifyPlant() async {
    final file = imageFile;
    if (file == null) return [];

    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('No signed-in user - sign-in must complete before identifying a plant.');
    }

    final tempPath = 'identify_temp/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref(tempPath);
    await ref.putFile(file);

    try {
      final result = await FirebaseFunctions.instance.httpsCallable('identifyPlant').call({
        'imagePath': tempPath,
        'organ': organ,
      });
      final data = result.data as List;
      return data
          .map((entry) => PlantSuggestion.fromMap(Map<String, dynamic>.from(entry)))
          .toList();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw Exception(e.message ?? 'Daily identification limit reached. Try again tomorrow.');
      }
      throw Exception(e.message ?? 'Failed to identify plant.');
    }
  }
}
