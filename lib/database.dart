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
        "INSERT INTO categories(name, spend_limit) VALUES ('Uncategorized', 0)");
    await db.execute(
        "CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, amount INT NOT NULL, transaction_date INT NOT NULL, category_id INT DEFAULT 0 NOT NULL, description TEXT, original_transaction_id TEXT UNIQUE, FOREIGN KEY (category_id) REFERENCES categories (id))");
  }

  Future<int> createCategory(CatchupCategory category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTransactionCategory(
      int transactionId, int categoryId) async {
    final db = await instance.database;
    return await db.rawUpdate(
        "UPDATE transactions SET category_id = ? WHERE id = ?",
        [categoryId, transactionId]);
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
    return await db.insert('transactions', transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCurrentMonthSum(int categoryId) async {
    final db = await instance.database;

    // get first date of current month
    DateTime now = DateTime.now();
    DateTime firstDate = DateTime(now.year, now.month, 1);
    int firstDateEpoch = firstDate.millisecondsSinceEpoch ~/ 1000;

    // get last date of current month
    DateTime lastDate = DateTime(now.year, now.month + 1, 0);
    int lastDateEpoch = lastDate.millisecondsSinceEpoch ~/ 1000;

    final List<Map<String, Object?>> queryResult = await db.rawQuery(
        "SELECT SUM(amount) AS total FROM transactions WHERE category_id = ? AND transaction_date BETWEEN ? AND ?",
        [categoryId, firstDateEpoch, lastDateEpoch]);

    if (queryResult[0]["total"] == null) {
      return 0;
    }
    int total = queryResult[0]['total'] as int;
    return total;
  }

  Future<List<CatchupTransaction>> getTransactionFromToDate(
      int categoryId, DateTime startDate, DateTime endDate) async {
    final db = await instance.database;

    int startEpoch = startDate.millisecondsSinceEpoch ~/ 1000;
    int endEpoch = endDate.millisecondsSinceEpoch ~/ 1000;

    final List<Map<String, Object?>> queryResult = await db.rawQuery(
        "SELECT * FROM transactions WHERE category_id = ? AND transaction_date BETWEEN ? AND ?",
        [categoryId, startEpoch, endEpoch]);

    return queryResult.map((e) => CatchupTransaction.fromMap(e)).toList();
  }

  Future<List<int>> getAggregateSumFromToDate(
      int categoryId, DateTime startDate, DateTime endDate) async {
    final db = await instance.database;

    DateTime currentDate = startDate;
    List<int> sums = [];

    while (currentDate.isBefore(endDate)) {
      int currentEpoch = currentDate.millisecondsSinceEpoch ~/ 1000;
      DateTime nextDate = currentDate.add(const Duration(days: 1));
      int nextDateEpoch = nextDate.millisecondsSinceEpoch ~/ 1000;
      final List<Map<String, Object?>> queryResult = await db.rawQuery(
          "SELECT SUM(amount) AS total FROM transactions WHERE category_id = ? AND transaction_date >= ? AND transaction_date < ?",
          [
            categoryId,
            currentEpoch,
            nextDateEpoch,
          ]);
      if (queryResult[0]["total"] == null) {
        sums.add(0);
      } else {
        sums.add(queryResult[0]["total"] as int);
      }
      currentDate = nextDate;
    }

    return sums;
  }

  Future<List<int>> getCurrentMonthTransactionSumByDay(int categoryId) async {
    final db = await instance.database;

    // get first date of current month
    DateTime now = DateTime.now();
    DateTime firstDate = DateTime(now.year, now.month, 1);

    // get last date of current month
    DateTime lastDate = DateTime(now.year, now.month + 1, 0);

    DateTime currentDate = firstDate;
    List<int> sums = [];

    while (currentDate.isBefore(lastDate)) {
      int currentEpoch = currentDate.millisecondsSinceEpoch ~/ 1000;
      DateTime nextDate = currentDate.add(const Duration(days: 1));
      int nextDateEpoch = nextDate.millisecondsSinceEpoch ~/ 1000;
      final List<Map<String, Object?>> queryResult = await db.rawQuery(
          "SELECT SUM(amount) AS total FROM transactions WHERE category_id = ? AND transaction_date >= ? AND transaction_date < ?",
          [
            categoryId,
            currentEpoch,
            nextDateEpoch,
          ]);
      if (queryResult[0]["total"] == null) {
        sums.add(0);
      } else {
        sums.add(queryResult[0]["total"] as int);
      }
      currentDate = nextDate;
    }

    return sums;
  }
}
