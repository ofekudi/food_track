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
      version: 3, // v3: add is_miss column
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
        created_at TEXT NOT NULL,
        is_miss INTEGER NOT NULL DEFAULT 0
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

    if (oldVersion < 3) {
      // Additive: flag for quick-logged "miss" entries. Existing rows default to 0.
      try {
        await db.execute(
            'ALTER TABLE eating_logs ADD COLUMN is_miss INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        // Column may already exist; ignore.
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
        'is_miss': 0,
      },
    );

    return id;
  }

  /// Quick-log a "miss" — the user ate but forgot to document it mindfully.
  /// Only the typed [description] matters; hunger/reason are neutral placeholders.
  Future<String> addMiss({
    required String description,
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
        'hunger_level': 0, // N/A for a miss
        'reason': 'hungry', // placeholder, ignored for misses
        'entry_date': entryDateStr,
        'created_at': now.toIso8601String(),
        'is_miss': 1,
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

  Future<List<Map<String, dynamic>>> getAllEatingLogs() async {
    final Database db = await database;
    return await db.query('eating_logs', orderBy: 'created_at DESC');
  }
}
