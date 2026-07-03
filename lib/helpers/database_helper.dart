import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/plant.dart';
import '../models/garden.dart';

class DatabaseHelper {
  static const _dbVersion = 2;
  static const _defaultGardenName = 'My Plants';

  static Database? _database;

  // Singleton pattern to ensure only one database instance is used
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'plants.db');
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE gardens(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )''');
        await db.execute('''CREATE TABLE plants(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          species TEXT,
          imagePath TEXT,
          careInstructions TEXT,
          gardenId INTEGER,
          lastWatered TEXT,
          wateringIntervalDays INTEGER
        )''');
        await db.insert('gardens', {'name': _defaultGardenName});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''CREATE TABLE gardens(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )''');
          await db.execute('ALTER TABLE plants ADD COLUMN gardenId INTEGER');
          await db.execute('ALTER TABLE plants ADD COLUMN lastWatered TEXT');
          await db.execute(
              'ALTER TABLE plants ADD COLUMN wateringIntervalDays INTEGER');

          final defaultGardenId =
              await db.insert('gardens', {'name': _defaultGardenName});
          await db.update('plants', {'gardenId': defaultGardenId});
        }
      },
    );
  }

  // --- Gardens ---

  Future<int> insertGarden(Garden garden) async {
    final db = await database;
    return db.insert('gardens', {'name': garden.name});
  }

  Future<List<Garden>> getGardens() async {
    final db = await database;
    final maps = await db.query('gardens', orderBy: 'id');
    return List.generate(maps.length, (i) => Garden.fromMap(maps[i]));
  }

  Future<void> updateGarden(Garden garden) async {
    final db = await database;
    await db.update(
      'gardens',
      {'name': garden.name},
      where: 'id = ?',
      whereArgs: [garden.id],
    );
  }

  /// Deletes a garden, reassigning its plants to the default garden rather
  /// than deleting them. The default garden itself cannot be deleted.
  Future<void> deleteGarden(int id) async {
    final defaultGardenId = await getOrCreateDefaultGardenId();
    if (id == defaultGardenId) return;

    final db = await database;
    await db.update(
      'plants',
      {'gardenId': defaultGardenId},
      where: 'gardenId = ?',
      whereArgs: [id],
    );
    await db.delete('gardens', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getOrCreateDefaultGardenId() async {
    final db = await database;
    final existing = await db.query(
      'gardens',
      where: 'name = ?',
      whereArgs: [_defaultGardenName],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    return db.insert('gardens', {'name': _defaultGardenName});
  }

  Future<int> getPlantCountForGarden(int gardenId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM plants WHERE gardenId = ?',
      [gardenId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- Plants ---

  Future<List<Plant>> getPlants() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('plants');
    return List.generate(maps.length, (i) {
      return Plant.fromMap(maps[i]);
    });
  }

  Future<List<Plant>> getPlantsByGarden(int gardenId) async {
    final db = await database;
    final maps = await db.query(
      'plants',
      where: 'gardenId = ?',
      whereArgs: [gardenId],
    );
    return List.generate(maps.length, (i) => Plant.fromMap(maps[i]));
  }

  Future<int> insertPlant(Plant plant) async {
    final db = await database;
    return db.insert(
      'plants',
      plant.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePlant(Plant plant) async {
    final db = await database;
    await db.update(
      'plants',
      plant.toMap(),
      where: 'id = ?',
      whereArgs: [plant.id],
    );
  }

  Future<void> markWatered(int plantId) async {
    final db = await database;
    await db.update(
      'plants',
      {'lastWatered': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [plantId],
    );
  }

  Future<void> deletePlant(int id) async {
    final db = await database;
    await db.delete('plants', where: 'id = ?', whereArgs: [id]);
  }
}
