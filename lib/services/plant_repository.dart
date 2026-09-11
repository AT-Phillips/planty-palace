import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/care_log_entry.dart';
import '../models/garden.dart';
import '../models/journal_entry.dart';
import '../models/plant.dart';
import '../models/plant_photo.dart';
import '../utils/care_kind.dart';
import 'auth_service.dart';
import 'photo_storage_service.dart';

/// Firestore-backed replacement for the old local-SQLite DatabaseHelper.
/// Every document lives under the current user's UID, so data is scoped per
/// account and syncs across devices/reinstalls via the same Firebase Auth
/// account. Firestore's client SDK has built-in offline caching, so this is
/// the single source of truth - there's no separate local database anymore.
class PlantRepository {
  static const defaultGardenName = 'My Plants';

  PlantRepository.raw();

  /// Test seam. Screens construct their repository directly as
  /// `PlantRepository()`, which makes them impossible to render in a widget
  /// test without a live Firestore. Routing that call through a replaceable
  /// factory lets a test install a fake for the whole app in one line,
  /// without threading a repository parameter through every screen.
  ///
  /// Production code never sets this, so the default path is unchanged.
  static PlantRepository Function()? testFactory;

  factory PlantRepository() => testFactory?.call() ?? PlantRepository.raw();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _uid {
    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError(
        'No signed-in user - ensureSignedIn() must run before any data access.',
      );
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _gardens => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('gardens');

  CollectionReference<Map<String, dynamic>> get _plants => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('plants');

  CollectionReference<Map<String, dynamic>> get _careLog => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('care_log');

  CollectionReference<Map<String, dynamic>> _photos(String plantId) =>
      _plants.doc(plantId).collection('photos');

  CollectionReference<Map<String, dynamic>> _journal(String plantId) =>
      _plants.doc(plantId).collection('journal');

  // --- Gardens ---

  Future<String> insertGarden(Garden garden) async {
    final doc = await _gardens.add(garden.toMap());
    return doc.id;
  }

  Future<List<Garden>> getGardens() async {
    final snapshot = await _gardens.orderBy(FieldPath.documentId).get();
    return snapshot.docs
        .map((d) => Garden.fromMap(d.data(), id: d.id))
        .toList();
  }

  Future<void> updateGarden(Garden garden) async {
    await _gardens.doc(garden.id).update(garden.toMap());
  }

  /// Deletes a garden, reassigning its plants to the default garden rather
  /// than deleting them. The default garden itself cannot be deleted.
  Future<void> deleteGarden(String id) async {
    final defaultGardenId = await getOrCreateDefaultGardenId();
    if (id == defaultGardenId) return;

    // One atomic batch rather than a round trip per plant: a Space with many
    // plants reassigned far faster, and can't half-move if interrupted.
    final toReassign = await _plants.where('gardenId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final doc in toReassign.docs) {
      batch.update(doc.reference, {'gardenId': defaultGardenId});
    }
    batch.delete(_gardens.doc(id));
    await batch.commit();
  }

  /// Hard-deletes every garden doc, including the default one - only for
  /// full account deletion, where there's no data left to reassign into.
  Future<void> deleteAllGardens() async {
    final snapshot = await _gardens.get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<String> getOrCreateDefaultGardenId() async {
    final existing =
        await _gardens
            .where('name', isEqualTo: defaultGardenName)
            .limit(1)
            .get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }
    final doc = await _gardens.add({'name': defaultGardenName});
    return doc.id;
  }

  Future<int> getPlantCountForGarden(String gardenId) async {
    final aggregate =
        await _plants.where('gardenId', isEqualTo: gardenId).count().get();
    return aggregate.count ?? 0;
  }

  /// Every plant plus the Spaces they live in, in two round trips.
  ///
  /// The hub screen previously issued one aggregate count *per Space* on top
  /// of a separate full plant fetch, so its load cost grew with the number of
  /// Spaces (nine round trips for five Spaces). Since it already needs the
  /// full plant list for the to-do section, the per-Space counts are derived
  /// from that same list instead - fewer reads, lower billing, and counts
  /// that can never disagree with the list they are counting.
  Future<({List<Garden> spaces, List<Plant> plants, Map<String, int> counts})>
  getHubSnapshot() async {
    final results = await Future.wait([_gardens.get(), _plants.get()]);

    final spaces =
        results[0].docs
            .map((d) => Garden.fromMap(d.data(), id: d.id))
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final plants =
        results[1].docs.map((d) => Plant.fromMap(d.data(), id: d.id)).toList();

    final counts = <String, int>{for (final s in spaces) s.id!: 0};
    for (final plant in plants) {
      // A plant with no gardenId (or one pointing at a deleted Space) simply
      // is not counted against any Space, rather than crashing the hub.
      final id = plant.gardenId;
      if (id != null && counts.containsKey(id)) {
        counts[id] = counts[id]! + 1;
      }
    }

    return (spaces: spaces, plants: plants, counts: counts);
  }

  /// How many care events were logged since [since] - the "done today"
  /// counter on the hub. A single query against the care log, rather than
  /// per-plant history fetches.
  Future<int> getCareEventCountSince(DateTime since) async {
    final aggregate =
        await _careLog
            .where('wateredAt', isGreaterThanOrEqualTo: since.toIso8601String())
            .count()
            .get();
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

  /// Records that [kind] was performed on a plant just now.
  ///
  /// The plant's "last performed" stamp and the care-log entry are written in
  /// a single atomic batch. Previously these were two sequential round trips,
  /// which was not only twice the latency on every tap of a water button but
  /// could also leave the plant marked cared-for with no history row (or the
  /// reverse) if the second write failed.
  Future<void> markCare(String plantId, CareKind kind) async {
    final now = DateTime.now().toIso8601String();
    final batch = _db.batch();
    batch.update(_plants.doc(plantId), {kind.lastPerformedField: now});
    batch.set(_careLog.doc(), {
      'plantId': plantId,
      'wateredAt': now,
      'type': kind.logType,
    });
    await batch.commit();
  }

  /// Records [kind] against many plants at once - the Care screen's bulk
  /// action. One batch for the whole selection rather than a pair of writes
  /// per plant, so selecting twenty plants costs one commit instead of forty
  /// round trips.
  ///
  /// Firestore caps a batch at 500 writes; each plant costs two, so the work
  /// is chunked to stay inside that limit.
  Future<void> markCareBulk(Iterable<String> plantIds, CareKind kind) async {
    final now = DateTime.now().toIso8601String();
    final ids = plantIds.toList();
    const perBatch = 200;

    for (var start = 0; start < ids.length; start += perBatch) {
      final chunk = ids.skip(start).take(perBatch);
      final batch = _db.batch();
      for (final id in chunk) {
        batch.update(_plants.doc(id), {kind.lastPerformedField: now});
        batch.set(_careLog.doc(), {
          'plantId': id,
          'wateredAt': now,
          'type': kind.logType,
        });
      }
      await batch.commit();
    }
  }

  Future<void> markWatered(String plantId) => markCare(plantId, CareKind.water);

  Future<void> markFertilized(String plantId) =>
      markCare(plantId, CareKind.feed);

  Future<void> markRepotted(String plantId) => markCare(plantId, CareKind.repot);

  Future<void> markPruned(String plantId) => markCare(plantId, CareKind.prune);

  /// Deletes a plant and everything hanging off it.
  ///
  /// The three subcollection reads run concurrently, and every delete is
  /// committed as a single atomic [WriteBatch]. Previously each document was
  /// deleted in its own sequential round trip, which was slow for a plant
  /// with any history and - worse - left orphaned care logs, photos, and
  /// journal entries behind if the app was killed partway through.
  Future<void> deletePlant(String id) async {
    final results = await Future.wait([
      _careLog.where('plantId', isEqualTo: id).get(),
      _photos(id).get(),
      _journal(id).get(),
    ]);

    final batch = _db.batch();
    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }
    batch.delete(_plants.doc(id));
    await batch.commit();

    // Storage objects live outside Firestore, so they can't join the batch.
    // Done after the commit: a leftover image file is harmless, whereas a
    // Firestore row pointing at a deleted file would render broken.
    await PhotoStorageService().deleteAllPhotosForPlant(id);
  }

  // --- Growth photo timeline ---

  Future<List<PlantPhoto>> getPhotos(String plantId) async {
    final snapshot =
        await _photos(plantId).orderBy('takenAt', descending: true).get();
    return snapshot.docs
        .map((d) => PlantPhoto.fromMap(d.data(), id: d.id))
        .toList();
  }

  /// Uploads a new dated photo, adds it to the timeline, and makes it the
  /// plant's cover photo (shown in list views) since it's the newest.
  Future<PlantPhoto> addPhoto(String plantId, File file) async {
    final doc = _photos(plantId).doc();
    final takenAt = DateTime.now().toIso8601String();
    final photoUrl = await PhotoStorageService().uploadTimelinePhoto(
      plantId,
      doc.id,
      file,
    );
    await doc.set({'photoUrl': photoUrl, 'takenAt': takenAt});
    await _plants.doc(plantId).update({
      'photoUrl': photoUrl,
      'imagePath': file.path,
    });
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
      await _plants.doc(plantId).update({
        'photoUrl': remaining.first.photoUrl,
        'imagePath': '',
      });
    }
  }

  /// Sets an existing timeline photo as the cover without changing the
  /// timeline itself.
  Future<void> setCoverPhoto(String plantId, PlantPhoto photo) async {
    await _plants.doc(plantId).update({
      'photoUrl': photo.photoUrl,
      'imagePath': '',
    });
  }

  // --- Care log ---

  /// [wateredAt] is a historical field name kept for backward compatibility
  /// with existing entries - it holds the timestamp for any care event type
  /// (watering or fertilizing), not just watering.
  Future<void> logCareEvent(
    String plantId,
    String wateredAt, {
    String type = 'watering',
  }) async {
    await _careLog.add({
      'plantId': plantId,
      'wateredAt': wateredAt,
      'type': type,
    });
  }

  /// Returns watering and fertilizing events for a plant, most recent first.
  /// Entries logged before fertilizing tracking existed have no `type`
  /// field and are treated as watering events.
  Future<List<CareLogEntry>> getCareHistory(String plantId) async {
    // An equality filter plus an order-by on a different field needs a
    // composite index (see firestore.indexes.json). If that index is missing
    // or still building, Firestore fails the query outright with
    // `failed-precondition` - which previously took the whole plant detail
    // screen's load down with it. Fall back to fetching the plant's entries
    // unordered and sorting them here: the same result, slightly more data
    // over the wire, and the screen keeps working while an index builds.
    QuerySnapshot<Map<String, dynamic>> snapshot;
    var sortLocally = false;
    try {
      snapshot =
          await _careLog
              .where('plantId', isEqualTo: plantId)
              .orderBy('wateredAt', descending: true)
              .get();
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      snapshot = await _careLog.where('plantId', isEqualTo: plantId).get();
      sortLocally = true;
    }

    final entries =
        snapshot.docs.map((d) {
          final data = d.data();
          return CareLogEntry(
            type: data['type'] as String? ?? 'watering',
            timestamp: data['wateredAt'] as String,
          );
        }).toList();

    // Timestamps are ISO-8601, so lexicographic order is chronological.
    if (sortLocally) {
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    return entries;
  }

  // --- Journal notes ---

  Future<List<JournalEntry>> getJournalEntries(String plantId) async {
    final snapshot =
        await _journal(plantId).orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((d) => JournalEntry.fromMap(d.data(), id: d.id))
        .toList();
  }

  Future<JournalEntry> addJournalEntry(String plantId, String text) async {
    final createdAt = DateTime.now().toIso8601String();
    final doc = await _journal(
      plantId,
    ).add({'text': text, 'createdAt': createdAt});
    return JournalEntry(id: doc.id, text: text, createdAt: createdAt);
  }

  Future<void> deleteJournalEntry(String plantId, String entryId) async {
    await _journal(plantId).doc(entryId).delete();
  }
}
