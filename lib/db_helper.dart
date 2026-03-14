import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'models/eating_log.dart';

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
      version: 2, // Bump version for migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE eating_logs(
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        hunger_level INTEGER NOT NULL,
        reason TEXT NOT NULL,
        entry_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_eating_logs_entry_date ON eating_logs(entry_date);');
    await db.execute('CREATE INDEX idx_eating_logs_created_at ON eating_logs(created_at);');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from version 1 (old food tracking schema) to version 2 (mindful eating)
      // Create new eating_logs table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS eating_logs(
          id TEXT PRIMARY KEY,
          description TEXT NOT NULL,
          hunger_level INTEGER NOT NULL,
          reason TEXT NOT NULL,
          entry_date TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_eating_logs_entry_date ON eating_logs(entry_date);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_eating_logs_created_at ON eating_logs(created_at);');

      // Migrate existing food_entries to eating_logs
      // We'll convert them with default hunger_level=3 and reason='hungry'
      try {
        final oldEntries = await db.query('food_entries');
        for (var entry in oldEntries) {
          await db.insert('eating_logs', {
            'id': entry['id'],
            'description': entry['name'],
            'hunger_level': 3, // Default middle hunger
            'reason': 'hungry', // Default reason
            'entry_date': entry['entry_date'],
            'created_at': entry['created_at'],
          });
        }
      } catch (e) {
        // Old table might not exist, that's okay
      }

      // Drop old tables
      try {
        await db.execute('DROP TABLE IF EXISTS food_entries');
        await db.execute('DROP TABLE IF EXISTS daily_summaries');
        await db.execute('DROP TABLE IF EXISTS favorites');
      } catch (e) {
        // Tables might not exist
      }
    }
  }

  // === Eating Log Methods ===

  Future<String> addEatingLog({
    required String description,
    required int hungerLevel,
    required EatingReason reason,
    required DateTime entryDate,
  }) async {
    final Database db = await database;
    final String id = uuid.v4();
    final now = DateTime.now();
    final String entryDateStr = DateFormat('yyyy-MM-dd').format(entryDate);

    await db.insert(
      'eating_logs',
      {
        'id': id,
        'description': description,
        'hunger_level': hungerLevel.clamp(1, 5),
        'reason': reason.name,
        'entry_date': entryDateStr,
        'created_at': now.toIso8601String(),
      },
    );

    return id;
  }

  Future<List<Map<String, dynamic>>> getEatingLogsForDate(DateTime date) async {
    final Database db = await database;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return await db.query(
      'eating_logs',
      where: 'entry_date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> deleteEatingLog(String id) async {
    final Database db = await database;
    await db.delete(
      'eating_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateEatingLog(EatingLog log) async {
    final Database db = await database;
    await db.update(
      'eating_logs',
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getEatingLogsBetweenDates(
      DateTime startDate, DateTime endDate) async {
    final Database db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    return await db.query(
      'eating_logs',
      where: 'entry_date >= ? AND entry_date <= ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllEatingLogs() async {
    final Database db = await database;
    return await db.query('eating_logs', orderBy: 'created_at DESC');
  }

  // === Analytics Methods ===

  /// Get counts by reason for a date range
  Future<Map<String, int>> getReasonCounts(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final results = await db.rawQuery('''
      SELECT reason, COUNT(*) as count
      FROM eating_logs
      WHERE entry_date >= ? AND entry_date <= ?
      GROUP BY reason
    ''', [startDateStr, endDateStr]);

    Map<String, int> counts = {
      'hungry': 0,
      'bored': 0,
      'craving': 0,
      'social': 0,
    };

    for (var row in results) {
      final reason = row['reason'] as String;
      counts[reason] = row['count'] as int;
    }

    return counts;
  }

  /// Get average hunger level for a date range
  Future<double> getAverageHungerLevel(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final result = await db.rawQuery('''
      SELECT AVG(hunger_level) as avg_hunger
      FROM eating_logs
      WHERE entry_date >= ? AND entry_date <= ?
    ''', [startDateStr, endDateStr]);

    if (result.isNotEmpty && result.first['avg_hunger'] != null) {
      return (result.first['avg_hunger'] as num).toDouble();
    }
    return 0.0;
  }

  /// Get count of entries by hour of day for time patterns
  Future<Map<int, int>> getHourlyDistribution(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final results = await db.rawQuery('''
      SELECT CAST(strftime('%H', created_at) AS INTEGER) as hour, COUNT(*) as count
      FROM eating_logs
      WHERE entry_date >= ? AND entry_date <= ?
      GROUP BY hour
      ORDER BY hour
    ''', [startDateStr, endDateStr]);

    Map<int, int> distribution = {};
    for (int i = 0; i < 24; i++) {
      distribution[i] = 0;
    }

    for (var row in results) {
      final hour = row['hour'] as int;
      distribution[hour] = row['count'] as int;
    }

    return distribution;
  }

  /// Get count of entries by day of week (0 = Monday, 6 = Sunday)
  Future<Map<int, int>> getWeekdayDistribution(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    // SQLite strftime('%w') returns 0-6 where 0 = Sunday
    final results = await db.rawQuery('''
      SELECT CAST(strftime('%w', entry_date) AS INTEGER) as weekday, COUNT(*) as count
      FROM eating_logs
      WHERE entry_date >= ? AND entry_date <= ?
      GROUP BY weekday
      ORDER BY weekday
    ''', [startDateStr, endDateStr]);

    // Convert SQLite weekday (0=Sunday) to Dart weekday (1=Monday...7=Sunday)
    Map<int, int> distribution = {};
    for (int i = 1; i <= 7; i++) {
      distribution[i] = 0;
    }

    for (var row in results) {
      final sqliteWeekday = row['weekday'] as int;
      // Convert: 0 (Sun) -> 7, 1 (Mon) -> 1, etc.
      final dartWeekday = sqliteWeekday == 0 ? 7 : sqliteWeekday;
      distribution[dartWeekday] = row['count'] as int;
    }

    return distribution;
  }

  /// Get count of low-mindful eating (hunger <= 2 and reason != hungry)
  Future<int> getLowMindfulEatingCount(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM eating_logs
      WHERE entry_date >= ? AND entry_date <= ?
      AND hunger_level <= 2
      AND reason != 'hungry'
    ''', [startDateStr, endDateStr]);

    return result.first['count'] as int;
  }

  /// Get hunger level distribution
  Future<Map<int, int>> getHungerLevelDistribution(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final results = await db.rawQuery('''
      SELECT hunger_level, COUNT(*) as count
      FROM eating_logs
      WHERE entry_date >= ? AND entry_date <= ?
      GROUP BY hunger_level
      ORDER BY hunger_level
    ''', [startDateStr, endDateStr]);

    Map<int, int> distribution = {};
    for (int i = 1; i <= 5; i++) {
      distribution[i] = 0;
    }

    for (var row in results) {
      final level = row['hunger_level'] as int;
      distribution[level] = row['count'] as int;
    }

    return distribution;
  }

  /// Get late night eating count (after 10 PM)
  Future<int> getLateNightEatingCount(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM eating_logs
      WHERE entry_date >= ? AND entry_date <= ?
      AND CAST(strftime('%H', created_at) AS INTEGER) >= 22
    ''', [startDateStr, endDateStr]);

    return result.first['count'] as int;
  }

  /// Get total entry count for a date range
  Future<int> getEntryCount(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM eating_logs
      WHERE entry_date >= ? AND entry_date <= ?
    ''', [startDateStr, endDateStr]);

    return result.first['count'] as int;
  }

  /// Get hourly distribution by reason for stacked bar chart
  Future<Map<int, Map<String, int>>> getHourlyDistributionByReason(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final results = await db.rawQuery('''
      SELECT CAST(strftime('%H', created_at) AS INTEGER) as hour,
             reason,
             COUNT(*) as count
      FROM eating_logs
      WHERE entry_date >= ? AND entry_date <= ?
      GROUP BY hour, reason
      ORDER BY hour, reason
    ''', [startDateStr, endDateStr]);

    // Initialize empty map for all hours
    Map<int, Map<String, int>> distribution = {};
    for (int i = 0; i < 24; i++) {
      distribution[i] = {
        'hungry': 0,
        'bored': 0,
        'craving': 0,
        'social': 0,
      };
    }

    for (var row in results) {
      final hour = row['hour'] as int;
      final reason = row['reason'] as String;
      final count = row['count'] as int;
      if (distribution[hour]!.containsKey(reason)) {
        distribution[hour]![reason] = count;
      }
    }

    return distribution;
  }
}
