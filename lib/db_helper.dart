import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'models/favorite_item.dart';

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
        meal_type TEXT NOT NULL
      )
    ''');

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
  }) async {
    final Database db = await database;
    final String id = uuid.v4();
    final now = DateTime.now();

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
      },
    );

    // Update daily summary
    await _updateDailySummary(now);

    return id;
  }

  Future<void> _updateDailySummary(DateTime date) async {
    final Database db = await database;
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];

    // Get all entries for the day
    final entries = await db.query(
      'food_entries',
      where: 'date(created_at) = ?',
      whereArgs: [dateStr],
    );

    // Calculate totals
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var entry in entries) {
      totalCalories += entry['calories'] as int;
      totalProtein += entry['protein'] as double;
      totalCarbs += entry['carbs'] as double;
      totalFat += entry['fat'] as double;
    }

    // Update or insert daily summary
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
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];

    return await db.query(
      'food_entries',
      where: 'date(created_at) = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getDailySummary(DateTime date) async {
    final Database db = await database;
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];

    final List<Map<String, dynamic>> summaries = await db.query(
      'daily_summaries',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    return summaries.isNotEmpty ? summaries.first : null;
  }

  Future<void> deleteFoodEntry(String id) async {
    final Database db = await database;
    final entry = await db.query(
      'food_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (entry.isNotEmpty) {
      final createdAt = DateTime.parse(entry.first['created_at'] as String);
      await db.delete(
        'food_entries',
        where: 'id = ?',
        whereArgs: [id],
      );
      await _updateDailySummary(createdAt);
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
    final dateStr = DateTime(date.year, date.month, date.day)
        .toIso8601String()
        .split('T')[0];

    final entries = await db.query(
      'food_entries',
      where: 'date(created_at) = ?',
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
      final mealType = entry['meal_type'] as String;
      counts[mealType] = (counts[mealType] ?? 0) + 1;
    }

    return counts;
  }

  // --- Favorites Methods ---

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
      conflictAlgorithm: ConflictAlgorithm
          .replace, // Replace if name exists? Or handle duplicates differently?
      // For now, let's assume unique IDs
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
      favorite.toMap(), // Use the toMap method from the FavoriteItem model
      where: 'id = ?',
      whereArgs: [favorite.id],
      conflictAlgorithm: ConflictAlgorithm
          .replace, // Or use ignore/fail based on desired behavior
    );
  }
}
