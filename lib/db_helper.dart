import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'models/favorite_item.dart';
import 'models/food_entry.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;
  static const uuid = Uuid();

  factory DBHelper() => _instance;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'food_tracking.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE food_entries(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calories INTEGER,
        protein REAL,
        carbs REAL,
        fat REAL,
        notes TEXT,
        created_at TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        entry_date TEXT NOT NULL
      )
    ''');
    await db
        .execute('CREATE INDEX idx_entry_date ON food_entries(entry_date);');

    await db.execute('''
      CREATE TABLE daily_summaries(
        date TEXT PRIMARY KEY,
        total_calories INTEGER,
        total_protein REAL,
        total_carbs REAL,
        total_fat REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        calories INTEGER DEFAULT 0,
        protein REAL DEFAULT 0.0,
        carbs REAL DEFAULT 0.0,
        fat REAL DEFAULT 0.0,
        meal_type TEXT NOT NULL
      )
    ''');
  }

  Future<String> addFoodEntry({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required String mealType,
    String? notes,
    required DateTime entryDate,
  }) async {
    final Database db = await database;
    final String id = uuid.v4();
    final now = DateTime.now();
    final String entryDateStr = DateFormat('yyyy-MM-dd').format(entryDate);

    await db.insert(
      'food_entries',
      {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'notes': notes,
        'created_at': now.toIso8601String(),
        'meal_type': mealType,
        'entry_date': entryDateStr,
      },
    );

    await _updateDailySummary(entryDate);

    return id;
  }

  Future<void> _updateDailySummary(DateTime date) async {
    final Database db = await database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final entries = await db.query(
      'food_entries',
      where: 'entry_date = ?',
      whereArgs: [dateStr],
    );

    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var entry in entries) {
      totalCalories += (entry['calories'] as int?) ?? 0;
      totalProtein += (entry['protein'] as double?) ?? 0.0;
      totalCarbs += (entry['carbs'] as double?) ?? 0.0;
      totalFat += (entry['fat'] as double?) ?? 0.0;
    }

    await db.insert(
      'daily_summaries',
      {
        'date': dateStr,
        'total_calories': totalCalories,
        'total_protein': totalProtein,
        'total_carbs': totalCarbs,
        'total_fat': totalFat,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getFoodEntriesForDate(
      DateTime date) async {
    final Database db = await database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return await db.query(
      'food_entries',
      where: 'entry_date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getDailySummary(DateTime date) async {
    final Database db = await database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final List<Map<String, dynamic>> summaries = await db.query(
      'daily_summaries',
      where: 'date = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    return summaries.isNotEmpty ? summaries.first : null;
  }

  Future<void> deleteFoodEntry(String id) async {
    final Database db = await database;
    final entries = await db.query(
      'food_entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (entries.isNotEmpty) {
      final entryDateStr = entries.first['entry_date'] as String?;
      await db.delete(
        'food_entries',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (entryDateStr != null) {
        try {
          final entryDate = DateFormat('yyyy-MM-dd').parse(entryDateStr);
          await _updateDailySummary(entryDate);
        } catch (e) {
          // print("Error parsing entry_date for summary update after delete: $e");
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> searchFoodEntries(String query) async {
    final Database db = await database;
    return await db.query(
      'food_entries',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, int>> getMealTypeCounts(DateTime date) async {
    final Database db = await database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final entries = await db.query(
      'food_entries',
      where: 'entry_date = ?',
      whereArgs: [dateStr],
    );
    Map<String, int> counts = {
      'Breakfast': 0,
      'Lunch': 0,
      'Dinner': 0,
      'Snack': 0,
      'Coffee': 0,
    };
    for (var entry in entries) {
      final mealType = entry['meal_type'] as String?;
      if (mealType != null && counts.containsKey(mealType)) {
        counts[mealType] = counts[mealType]! + 1;
      }
    }
    return counts;
  }

  Future<String> addFavorite({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required String mealType,
  }) async {
    final Database db = await database;
    final String id = uuid.v4();

    await db.insert(
      'favorites',
      {
        'id': id,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'meal_type': mealType,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    final Database db = await database;
    return await db.query('favorites', orderBy: 'name ASC');
  }

  Future<void> deleteFavorite(String id) async {
    final Database db = await database;
    await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateFavorite(FavoriteItem favorite) async {
    final Database db = await database;
    await db.update(
      'favorites',
      favorite.toMap(),
      where: 'id = ?',
      whereArgs: [favorite.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    final Database db = await database;
    await db.update(
      'food_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _updateDailySummary(entry.entryDate);
  }

  Future<List<Map<String, dynamic>>> getFoodEntriesBetweenDates(
      DateTime startDate, DateTime endDate) async {
    final Database db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    return await db.query(
      'food_entries',
      where: 'entry_date >= ? AND entry_date <= ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'created_at ASC',
    );
  }

  Future<Map<String, int>> getAllFoodFrequencies() async {
    final db = await database;

    // Get frequencies from food entries
    final List<Map<String, dynamic>> entriesResult = await db.rawQuery('''
      SELECT name, COUNT(*) as frequency
      FROM food_entries
      GROUP BY name
    ''');

    // Convert to Map<String, int>
    Map<String, int> frequencies = {};
    for (var row in entriesResult) {
      frequencies[row['name'] as String] = row['frequency'] as int;
    }

    // Add favorites to the frequencies (count as 1 if not already counted)
    final List<Map<String, dynamic>> favorites = await db.query('favorites');
    for (var favorite in favorites) {
      String name = favorite['name'] as String;
      frequencies[name] = frequencies[name] ?? 1;
    }

    return frequencies;
  }

  Future<List<String>> searchFoodNames(String query) async {
    final db = await database;

    // Search in both food entries and favorites
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT DISTINCT name, 
             (SELECT COUNT(*) FROM food_entries fe WHERE fe.name = e.name) as frequency
      FROM (
        SELECT name FROM food_entries
        UNION
        SELECT name FROM favorites
      ) e
      WHERE name LIKE ?
      ORDER BY frequency DESC
      LIMIT 5
    ''', ['%$query%']);

    return results.map((row) => row['name'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getUniqueFoodItems() async {
    final db = await database;
    // Select the most recent data for each unique food name
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT name, calories, protein, carbs, fat, meal_type
      FROM (
        SELECT
          name, calories, protein, carbs, fat, meal_type,
          ROW_NUMBER() OVER(PARTITION BY name ORDER BY created_at DESC) as rn
        FROM food_entries
      )
      WHERE rn = 1
      ORDER BY name ASC;
    ''');
    return results;
  }
}
