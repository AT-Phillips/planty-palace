import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'plants.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE plants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            species TEXT,
            wateringSchedule TEXT,
            lastWatered TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertPlant(Map<String, dynamic> plant) async {
    Database db = await database;
    return await db.insert('plants', plant);
  }

  Future<List<Map<String, dynamic>>> getPlants() async {
    Database db = await database;
    return await db.query('plants');
  }

  Future<int> updatePlant(Map<String, dynamic> plant) async {
    Database db = await database;
    return await db.update(
      'plants',
      plant,
      where: 'id = ?',
      whereArgs: [plant['id']],
    );
  }

  Future<int> deletePlant(int id) async {
    Database db = await database;
    return await db.delete(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
