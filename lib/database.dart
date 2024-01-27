import 'package:mobile/models/category.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class CatchupDatabase {
  static final CatchupDatabase instance = CatchupDatabase._init();

  static Database? _database;

  CatchupDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('catchup.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, filePath);

    return await openDatabase(path, onCreate: _createDB, version: 2);
  }

  // initial database creation
  Future _createDB(Database db, int version) async {
    await db.execute(
        "CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, spend_limit INTEGER NOT NULL)");
  }

  Future<int> createCategory(CatchupCategory category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CatchupCategory>> getAllCategories() async {
    final db = await instance.database;
    final List<Map<String, Object?>> queryResult =
        await db.query('categories', orderBy: "id DESC");
    return queryResult.map((e) => CatchupCategory.fromMap(e)).toList();
  }
  
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
