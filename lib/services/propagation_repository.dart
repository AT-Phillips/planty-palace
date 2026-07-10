import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/plant_photo.dart';
import '../models/propagation.dart';
import 'auth_service.dart';
import 'photo_storage_service.dart';

/// Firestore-backed repository for Propagations - mirrors PlantRepository's
/// shape (kept as a separate parallel repository rather than a shared
/// generic base, matching this codebase's existing convention of small
/// parallel services).
class PropagationRepository {
  String get _uid {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError(
        'No signed-in user - ensureSignedIn() must run before any data access.',
      );
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _propagations =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('propagations');

  CollectionReference<Map<String, dynamic>> _photos(String propagationId) =>
      _propagations.doc(propagationId).collection('photos');

  Future<String> insertPropagation(Propagation propagation) async {
    final doc = await _propagations.add(propagation.toMap());
    return doc.id;
  }

  Future<List<Propagation>> getPropagations() async {
    final snapshot =
        await _propagations.orderBy('startedAt', descending: true).get();
    return snapshot.docs
        .map((d) => Propagation.fromMap(d.data(), id: d.id))
        .toList();
  }

  Future<int> getPropagationCount() async {
    final aggregate = await _propagations.count().get();
    return aggregate.count ?? 0;
  }

  Future<void> updatePropagation(Propagation propagation) async {
    await _propagations.doc(propagation.id).update(propagation.toMap());
  }

  Future<void> deletePropagation(String id) async {
    await _propagations.doc(id).delete();
    await PhotoStorageService().deleteAllPhotosForPlant(id);
  }

  Future<void> markPromoted(
    String propagationId,
    String promotedPlantId,
  ) async {
    await _propagations.doc(propagationId).update({
      'isPromoted': true,
      'promotedPlantId': promotedPlantId,
    });
  }

  // --- Growth photo timeline (mirrors PlantRepository) ---

  Future<List<PlantPhoto>> getPhotos(String propagationId) async {
    final snapshot =
        await _photos(propagationId).orderBy('takenAt', descending: true).get();
    return snapshot.docs
        .map((d) => PlantPhoto.fromMap(d.data(), id: d.id))
        .toList();
  }

  Future<PlantPhoto> addPhoto(String propagationId, File file) async {
    final doc = _photos(propagationId).doc();
    final takenAt = DateTime.now().toIso8601String();
    final photoUrl = await PhotoStorageService().uploadTimelinePhoto(
      propagationId,
      doc.id,
      file,
    );
    await doc.set({'photoUrl': photoUrl, 'takenAt': takenAt});
    await _propagations.doc(propagationId).update({
      'photoUrl': photoUrl,
      'imagePath': file.path,
    });
    return PlantPhoto(id: doc.id, photoUrl: photoUrl, takenAt: takenAt);
  }

  Future<void> deletePhoto(String propagationId, PlantPhoto photo) async {
    await PhotoStorageService().deleteTimelinePhoto(propagationId, photo.id);
    await _photos(propagationId).doc(photo.id).delete();

    final doc = await _propagations.doc(propagationId).get();
    final currentCoverUrl = doc.data()?['photoUrl'] as String?;
    if (currentCoverUrl != photo.photoUrl) return;

    final remaining = await getPhotos(propagationId);
    if (remaining.isEmpty) {
      await _propagations.doc(propagationId).update({
        'photoUrl': null,
        'imagePath': '',
      });
    } else {
      await _propagations.doc(propagationId).update({
        'photoUrl': remaining.first.photoUrl,
        'imagePath': '',
      });
    }
  }

  Future<void> setCoverPhoto(String propagationId, PlantPhoto photo) async {
    await _propagations.doc(propagationId).update({
      'photoUrl': photo.photoUrl,
      'imagePath': '',
    });
  }
}
