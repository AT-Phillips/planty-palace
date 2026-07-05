import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'auth_service.dart';

/// Handles syncing plant photos to/from Firebase Storage, so a plant's
/// photo actually comes back on a new device or reinstall - not just its
/// text data.
class PhotoStorageService {
  String get _uid {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('No signed-in user - ensureSignedIn() must run before any photo access.');
    }
    return uid;
  }

  Reference _photoRef(String plantId) =>
      FirebaseStorage.instance.ref('plant_photos/$_uid/$plantId.jpg');

  Future<String> uploadPlantPhoto(String plantId, File file) async {
    final ref = _photoRef(plantId);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> deletePlantPhoto(String plantId) async {
    try {
      await _photoRef(plantId).delete();
    } catch (_) {
      // Nothing to delete, or already gone - not an error worth surfacing.
    }
  }

  /// Returns a local file for this plant's photo, downloading it from
  /// [photoUrl] first if it isn't already cached on this device (e.g. a
  /// plant that just synced in from another device).
  Future<File> ensureLocalCopy(String plantId, String photoUrl) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(appDocDir.path, 'synced_photos'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final localFile = File(p.join(cacheDir.path, '$plantId.jpg'));
    if (await localFile.exists()) {
      return localFile;
    }

    final response = await http.get(Uri.parse(photoUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download photo: ${response.statusCode}');
    }
    await localFile.writeAsBytes(response.bodyBytes);
    return localFile;
  }
}
