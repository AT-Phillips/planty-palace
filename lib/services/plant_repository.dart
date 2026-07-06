import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/garden.dart';
import '../models/plant.dart';
import '../models/plant_photo.dart';
import 'auth_service.dart';
import 'photo_storage_service.dart';

/// Firestore-backed replacement for the old local-SQLite DatabaseHelper.
/// Every document lives under the current user's UID, so data is scoped per
/// account and syncs across devices/reinstalls via the same Firebase Auth
/// account. Firestore's client SDK has built-in offline caching, so this is
/// the single source of truth - there's no separate local database anymore.
class PlantRepository {
  static const _defaultGardenName = 'My Plants';

  String get _uid {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('No signed-in user - ensureSignedIn() must run before any data access.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _gardens =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('gardens');

  CollectionReference<Map<String, dynamic>> get _plants =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('plants');

  CollectionReference<Map<String, dynamic>> get _careLog =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('care_log');

  CollectionReference<Map<String, dynamic>> _photos(String plantId) =>
      _plants.doc(plantId).collection('photos');

  // --- Gardens ---

  Future<String> insertGarden(Garden garden) async {
    final doc = await _gardens.add(garden.toMap());
    return doc.id;
  }

  Future<List<Garden>> getGardens() async {
    final snapshot = await _gardens.orderBy(FieldPath.documentId).get();
    return snapshot.docs.map((d) => Garden.fromMap(d.data(), id: d.id)).toList();
  }

  Future<void> updateGarden(Garden garden) async {
    await _gardens.doc(garden.id).update(garden.toMap());
  }

  /// Deletes a garden, reassigning its plants to the default garden rather
  /// than deleting them. The default garden itself cannot be deleted.
  Future<void> deleteGarden(String id) async {
    final defaultGardenId = await getOrCreateDefaultGardenId();
    if (id == defaultGardenId) return;

    final toReassign = await _plants.where('gardenId', isEqualTo: id).get();
    for (final doc in toReassign.docs) {
      await doc.reference.update({'gardenId': defaultGardenId});
    }
    await _gardens.doc(id).delete();
  }

  Future<String> getOrCreateDefaultGardenId() async {
    final existing =
        await _gardens.where('name', isEqualTo: _defaultGardenName).limit(1).get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }
    final doc = await _gardens.add({'name': _defaultGardenName});
    return doc.id;
  }

  Future<int> getPlantCountForGarden(String gardenId) async {
    final aggregate = await _plants.where('gardenId', isEqualTo: gardenId).count().get();
    return aggregate.count ?? 0;
  }

  // --- Plants ---

  Future<List<Plant>> getPlants() async {
    final snapshot = await _plants.get();
    return snapshot.docs.map((d) => Plant.fromMap(d.data(), id: d.id)).toList();
  }

  Future<List<Plant>> getPlantsByGarden(String gardenId) async {
    final snapshot = await _plants.where('gardenId', isEqualTo: gardenId).get();
    return snapshot.docs.map((d) => Plant.fromMap(d.data(), id: d.id)).toList();
  }

  Future<String> insertPlant(Plant plant) async {
    final doc = await _plants.add(plant.toMap());
    return doc.id;
  }

  Future<void> updatePlant(Plant plant) async {
    await _plants.doc(plant.id).update(plant.toMap());
  }

  Future<void> markWatered(String plantId) async {
    final now = DateTime.now().toIso8601String();
    await _plants.doc(plantId).update({'lastWatered': now});
    await logCareEvent(plantId, now);
  }

  Future<void> deletePlant(String id) async {
    await _plants.doc(id).delete();

    final logs = await _careLog.where('plantId', isEqualTo: id).get();
    for (final doc in logs.docs) {
      await doc.reference.delete();
    }

    await PhotoStorageService().deleteAllPhotosForPlant(id);
  }

  // --- Growth photo timeline ---

  Future<List<PlantPhoto>> getPhotos(String plantId) async {
    final snapshot = await _photos(plantId).orderBy('takenAt', descending: true).get();
    return snapshot.docs.map((d) => PlantPhoto.fromMap(d.data(), id: d.id)).toList();
  }

  /// Uploads a new dated photo, adds it to the timeline, and makes it the
  /// plant's cover photo (shown in list views) since it's the newest.
  Future<PlantPhoto> addPhoto(String plantId, File file) async {
    final doc = _photos(plantId).doc();
    final takenAt = DateTime.now().toIso8601String();
    final photoUrl = await PhotoStorageService().uploadTimelinePhoto(plantId, doc.id, file);
    await doc.set({'photoUrl': photoUrl, 'takenAt': takenAt});
    await _plants.doc(plantId).update({'photoUrl': photoUrl, 'imagePath': file.path});
    return PlantPhoto(id: doc.id, photoUrl: photoUrl, takenAt: takenAt);
  }

  /// Deletes one timeline photo. If it was the current cover, the next most
  /// recent remaining photo becomes the new cover (or the cover is cleared
  /// if none remain).
  Future<void> deletePhoto(String plantId, PlantPhoto photo) async {
    await PhotoStorageService().deleteTimelinePhoto(plantId, photo.id);
    await _photos(plantId).doc(photo.id).delete();

    final plantDoc = await _plants.doc(plantId).get();
    final currentCoverUrl = plantDoc.data()?['photoUrl'] as String?;
    if (currentCoverUrl != photo.photoUrl) return;

    final remaining = await getPhotos(plantId);
    if (remaining.isEmpty) {
      await _plants.doc(plantId).update({'photoUrl': null, 'imagePath': ''});
    } else {
      await _plants.doc(plantId).update({'photoUrl': remaining.first.photoUrl, 'imagePath': ''});
    }
  }

  /// Sets an existing timeline photo as the cover without changing the
  /// timeline itself.
  Future<void> setCoverPhoto(String plantId, PlantPhoto photo) async {
    await _plants.doc(plantId).update({'photoUrl': photo.photoUrl, 'imagePath': ''});
  }

  // --- Care log ---

  Future<void> logCareEvent(String plantId, String wateredAt) async {
    await _careLog.add({'plantId': plantId, 'wateredAt': wateredAt});
  }

  /// Returns watering timestamps for a plant, most recent first.
  Future<List<String>> getCareHistory(String plantId) async {
    final snapshot = await _careLog
        .where('plantId', isEqualTo: plantId)
        .orderBy('wateredAt', descending: true)
        .get();
    return snapshot.docs.map((d) => d.data()['wateredAt'] as String).toList();
  }
}
