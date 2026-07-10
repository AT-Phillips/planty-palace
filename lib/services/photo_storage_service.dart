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
      throw StateError(
        'No signed-in user - ensureSignedIn() must run before any photo access.',
      );
    }
    return uid;
  }

  Reference _timelinePhotoRef(String plantId, String photoId) =>
      FirebaseStorage.instance.ref('plant_photos/$_uid/$plantId/$photoId.jpg');

  Reference _profilePhotoRef(String uid) =>
      FirebaseStorage.instance.ref('profile_photos/$uid.jpg');

  Future<String> uploadProfilePhoto(String uid, File file) async {
    final ref = _profilePhotoRef(uid);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> deleteProfilePhoto(String uid) async {
    try {
      await _profilePhotoRef(uid).delete();
    } catch (_) {
      // Nothing to delete, or already gone - not an error worth surfacing.
    }
  }

  Future<String> uploadTimelinePhoto(
    String plantId,
    String photoId,
    File file,
  ) async {
    final ref = _timelinePhotoRef(plantId, photoId);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> deleteTimelinePhoto(String plantId, String photoId) async {
    try {
      await _timelinePhotoRef(plantId, photoId).delete();
    } catch (_) {
      // Nothing to delete, or already gone - not an error worth surfacing.
    }
  }

  /// Deletes every photo ever uploaded for this plant - used when the plant
  /// itself is deleted.
  Future<void> deleteAllPhotosForPlant(String plantId) async {
    try {
      final folder = FirebaseStorage.instance.ref(
        'plant_photos/$_uid/$plantId',
      );
      final listing = await folder.listAll();
      for (final item in listing.items) {
        await item.delete();
      }
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

    // One short retry on transient failures (dropped connection, brief
    // server hiccup) before giving up - cheap reliability improvement for
    // something that otherwise fails permanently on the first blip.
    http.Response? response;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        response = await http.get(Uri.parse(photoUrl));
        if (response.statusCode == 200) break;
      } catch (_) {
        if (attempt == 1) rethrow;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    if (response == null || response.statusCode != 200) {
      throw Exception('Failed to download photo: ${response?.statusCode}');
    }
    await localFile.writeAsBytes(response.bodyBytes);
    return localFile;
  }
}
