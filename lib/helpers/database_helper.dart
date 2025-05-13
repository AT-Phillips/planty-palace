import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/plant.dart';

class DatabaseHelper {
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
    return openDatabase(path, version: 1, onCreate: (db, version) {
      return db.execute(
        '''CREATE TABLE plants(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          species TEXT,
          imagePath TEXT,
          careInstructions TEXT
        )''',
      );
    });
  }

  // Fetch all plants from the database
  Future<List<Plant>> getPlants() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('plants');
    return List.generate(maps.length, (i) {
      return Plant.fromMap(maps[i]);
    });
  }

  // Insert a new plant into the database
  Future<void> insertPlant(Plant plant) async {
    final db = await database;
    await db.insert(
      'plants',
      plant.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update an existing plant
  Future<void> updatePlant(Plant plant) async {
    final db = await database;
    await db.update(
      'plants',
      plant.toMap(),
      where: 'id = ?',
      whereArgs: [plant.id],
    );
  }

  // Delete a plant from the database
  Future<void> deletePlant(int id) async {
    final db = await database;
    await db.delete(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
