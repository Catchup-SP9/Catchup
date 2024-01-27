import 'package:mobile/models/category.dart';
import 'package:mobile/models/transaction.dart';
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

    return await openDatabase(path, onCreate: _createDB, version: 3);
  }

  // initial database creation
  Future _createDB(Database db, int version) async {
    // enable foreign keys
    await db.execute("PRAGMA foreign_keys = ON");
    await db.execute(
        "CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, spend_limit INTEGER NOT NULL)");
    await db.execute(
        "CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, amount INT NOT NULL, transaction_date INT NOT NULL, category_id INT DEFAULT 0 NOT NULL, FOREIGN KEY (category_id) REFERENCES categories (id))");
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

  Future<int> createTransaction(CatchupTransaction transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> sum_for_category(int category_id) async {
    final db = await instance.database;
    int sum = 0;
    for (var row in await db.rawQuery('SELECT amount FROM transactions WHERE category_id = ?', [category_id])) {
      sum += int.parse(row['amount'].toString());
    }
    return sum;
  }
}


