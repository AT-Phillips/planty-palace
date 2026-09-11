import 'dart:io';

import 'package:planty_palace/models/garden.dart';
import 'package:planty_palace/models/plant.dart';
import 'package:planty_palace/models/plant_photo.dart';
import 'package:planty_palace/models/propagation.dart';
import 'package:planty_palace/models/wishlist_item.dart';
import 'package:planty_palace/services/plant_repository.dart';
import 'package:planty_palace/services/propagation_repository.dart';
import 'package:planty_palace/services/wishlist_repository.dart';
import 'package:planty_palace/utils/care_kind.dart';

/// In-memory stand-ins for the Firestore-backed repositories, installed via
/// the `testFactory` seams so whole screens can be rendered and driven in a
/// widget test without a live backend.
///
/// Only the methods the screens actually call are overridden; anything else
/// would still hit Firestore, which surfaces immediately as a test failure
/// rather than silently passing.

/// A timestamp [days] in the past, as the ISO-8601 string the models store.
String daysAgo(int days) =>
    DateTime.now().subtract(Duration(days: days)).toIso8601String();

/// A fixed sample collection covering every care state the UI renders:
/// badly overdue, due today, comfortably scheduled, and unscheduled.
List<Plant> samplePlants() => [
  Plant(
    id: 'p1',
    name: 'Fiddle Leaf Fig',
    species: 'Ficus lyrata',
    imagePath: '',
    careInstructions: '',
    gardenId: 'g1',
    lastWatered: daysAgo(12),
    wateringIntervalDays: 7,
    lastFertilized: daysAgo(40),
    fertilizingIntervalDays: 30,
  ),
  Plant(
    id: 'p2',
    name: 'Monstera',
    species: 'Monstera deliciosa',
    imagePath: '',
    careInstructions: '',
    gardenId: 'g1',
    lastWatered: daysAgo(7),
    wateringIntervalDays: 7,
  ),
  Plant(
    id: 'p3',
    name: 'Snake Plant',
    species: 'Dracaena trifasciata',
    imagePath: '',
    careInstructions: '',
    gardenId: 'g2',
    lastWatered: daysAgo(2),
    wateringIntervalDays: 21,
  ),
  Plant(
    id: 'p4',
    name: 'Pilea',
    species: 'Pilea peperomioides',
    imagePath: '',
    careInstructions: '',
    gardenId: 'g2',
    lastWatered: daysAgo(9),
    wateringIntervalDays: 8,
  ),
  Plant(
    id: 'p5',
    name: 'ZZ Plant',
    species: 'Zamioculcas zamiifolia',
    imagePath: '',
    careInstructions: '',
    gardenId: 'g1',
  ),
];

List<Garden> sampleGardens() => [
  Garden(id: 'g1', name: 'Living Room'),
  Garden(id: 'g2', name: 'Bedroom'),
];

class FakePlantRepository extends PlantRepository {
  FakePlantRepository({List<Plant>? plants, List<Garden>? gardens})
    : plants = plants ?? samplePlants(),
      gardens = gardens ?? sampleGardens(),
      super.raw();

  /// Makes every read throw, to exercise the error states.
  FakePlantRepository.failing()
    : plants = [],
      gardens = [],
      shouldFail = true,
      super.raw();

  List<Plant> plants;
  List<Garden> gardens;
  bool shouldFail = false;

  /// Records what the UI asked the repository to do, so a test can assert on
  /// behaviour rather than only on pixels.
  final List<String> calls = [];

  void _guard() {
    if (shouldFail) throw StateError('offline');
  }

  @override
  Future<List<Plant>> getPlants() async {
    _guard();
    return List.of(plants);
  }

  @override
  Future<List<Plant>> getPlantsByGarden(String gardenId) async {
    _guard();
    return plants.where((p) => p.gardenId == gardenId).toList();
  }

  @override
  Future<List<Garden>> getGardens() async {
    _guard();
    return List.of(gardens);
  }

  @override
  Future<({Map<String, int> counts, List<Plant> plants, List<Garden> spaces})>
  getHubSnapshot() async {
    _guard();
    final counts = <String, int>{for (final g in gardens) g.id!: 0};
    for (final plant in plants) {
      final id = plant.gardenId;
      if (id != null && counts.containsKey(id)) counts[id] = counts[id]! + 1;
    }
    return (spaces: List.of(gardens), plants: List.of(plants), counts: counts);
  }

  @override
  Future<int> getCareEventCountSince(DateTime since) async {
    _guard();
    return 2;
  }

  @override
  Future<int> getPlantCountForGarden(String gardenId) async {
    _guard();
    return plants.where((p) => p.gardenId == gardenId).length;
  }

  @override
  Future<String> getOrCreateDefaultGardenId() async => 'g1';

  @override
  Future<void> markCare(String plantId, CareKind kind) async {
    calls.add('markCare:$plantId:${kind.name}');
    final index = plants.indexWhere((p) => p.id == plantId);
    if (index != -1) {
      plants[index] = kind.withPerformed(plants[index], DateTime.now());
    }
  }

  @override
  Future<void> markCareBulk(Iterable<String> plantIds, CareKind kind) async {
    calls.add('markCareBulk:${plantIds.length}:${kind.name}');
    for (final id in plantIds) {
      final index = plants.indexWhere((p) => p.id == id);
      if (index != -1) {
        plants[index] = kind.withPerformed(plants[index], DateTime.now());
      }
    }
  }

  @override
  Future<void> deletePlant(String id) async {
    calls.add('deletePlant:$id');
    plants.removeWhere((p) => p.id == id);
  }

  @override
  Future<String> insertGarden(Garden garden) async {
    calls.add('insertGarden:${garden.name}');
    final id = 'g${gardens.length + 1}';
    gardens.add(Garden(id: id, name: garden.name));
    return id;
  }

  @override
  Future<void> updateGarden(Garden garden) async {
    calls.add('updateGarden:${garden.id}:${garden.name}');
    final index = gardens.indexWhere((g) => g.id == garden.id);
    if (index != -1) gardens[index] = garden;
  }

  @override
  Future<void> deleteGarden(String id) async {
    calls.add('deleteGarden:$id');
    gardens.removeWhere((g) => g.id == id);
  }

  @override
  Future<List<PlantPhoto>> getPhotos(String plantId) async => [];
}

class FakePropagationRepository extends PropagationRepository {
  FakePropagationRepository({this.count = 3}) : super.raw();

  final int count;

  @override
  Future<int> getPropagationCount() async => count;

  @override
  Future<List<Propagation>> getPropagations() async => [];
}

class FakeWishlistRepository extends WishlistRepository {
  FakeWishlistRepository({List<WishlistItem>? items})
    : items = items ?? sampleWishlist(),
      super.raw();

  final List<WishlistItem> items;

  static List<WishlistItem> sampleWishlist() => [
    WishlistItem(
      id: 'monstera_adansonii',
      scientificName: 'Monstera adansonii',
      commonName: 'Swiss Cheese Vine',
      savedAt: daysAgo(3),
    ),
    WishlistItem(
      id: 'calathea_orbifolia',
      scientificName: 'Calathea orbifolia',
      commonName: 'Prayer Plant',
      savedAt: daysAgo(9),
    ),
  ];

  @override
  Future<List<WishlistItem>> getWishlist() async => List.of(items);
}

/// Installs the fakes for the duration of a test. Returns the plant fake so
/// the test can inspect [FakePlantRepository.calls] or mutate its data.
FakePlantRepository installFakeRepositories({
  FakePlantRepository? plantRepository,
  int propagationCount = 3,
  List<WishlistItem>? wishlist,
}) {
  final plants = plantRepository ?? FakePlantRepository();
  PlantRepository.testFactory = () => plants;
  PropagationRepository.testFactory =
      () => FakePropagationRepository(count: propagationCount);
  WishlistRepository.testFactory = () => FakeWishlistRepository(items: wishlist);
  return plants;
}

void clearFakeRepositories() {
  PlantRepository.testFactory = null;
  PropagationRepository.testFactory = null;
  WishlistRepository.testFactory = null;
}

/// Guards against a stray real file read in a widget test.
bool photoFileExists(String path) => path.isNotEmpty && File(path).existsSync();
