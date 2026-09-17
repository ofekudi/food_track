import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'models/day_mode.dart';
import 'models/entry.dart';
import 'models/meal_slot.dart';

/// Storage for the slot tracker.
///
/// This is a fresh database rather than a migration of the old
/// `food_tracking.db` — the previous schema tracked a different method
/// entirely, and none of its rows mean anything here. The old file is left
/// untouched on disk.
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;
  static const _uuid = Uuid();

  factory DBHelper() => _instance;

  DBHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'slots.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE days(
        date TEXT PRIMARY KEY,
        mode TEXT NOT NULL DEFAULT 'normal'
      )
    ''');
    await db.execute('''
      CREATE TABLE entries(
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        slot TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_entries_date ON entries(date)');
  }

  // === Entries ===

  Future<Entry> addEntry({
    required DateTime date,
    required MealSlot slot,
    required String text,
  }) async {
    final db = await database;
    final entry = Entry(
      id: _uuid.v4(),
      date: formatDay(date),
      slot: slot,
      text: text,
      createdAt: _timestampFor(date, slot),
    );
    await db.insert('entries', entry.toMap());
    return entry;
  }

  /// Back-filling yesterday at 23:00 shouldn't make breakfast sort last, so
  /// an entry logged for a past day is stamped at that slot's usual time
  /// instead of right now.
  DateTime _timestampFor(DateTime date, MealSlot slot) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return now;
    }
    return DateTime(date.year, date.month, date.day)
        .add(Duration(minutes: slot.defaultMinutes));
  }

  Future<List<Entry>> entriesForDate(DateTime date) async {
    final db = await database;
    final rows = await db.query(
      'entries',
      where: 'date = ?',
      whereArgs: [formatDay(date)],
      orderBy: 'created_at ASC',
    );
    return rows.map(Entry.fromMap).toList();
  }

  /// Every entry from [from] onward, for the week strip and the streak.
  Future<List<Entry>> entriesSince(DateTime from) async {
    final db = await database;
    final rows = await db.query(
      'entries',
      where: 'date >= ?',
      whereArgs: [formatDay(from)],
      orderBy: 'created_at ASC',
    );
    return rows.map(Entry.fromMap).toList();
  }

  Future<void> updateEntryText(String id, String text) async {
    final db = await database;
    await db.update('entries', {'text': text},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteEntry(String id) async {
    final db = await database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  // === Days ===

  /// The mode you set for [date], or null if you never said — the caller
  /// decides what an untouched day defaults to.
  Future<DayMode?> modeForDate(DateTime date) async {
    final db = await database;
    final rows = await db.query(
      'days',
      where: 'date = ?',
      whereArgs: [formatDay(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DayMode.fromString(rows.first['mode'] as String?);
  }

  Future<void> setModeForDate(DateTime date, DayMode mode) async {
    final db = await database;
    await db.insert(
      'days',
      {'date': formatDay(date), 'mode': mode.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, DayMode>> modesSince(DateTime from) async {
    final db = await database;
    final rows = await db.query(
      'days',
      where: 'date >= ?',
      whereArgs: [formatDay(from)],
    );
    return {
      for (final row in rows)
        row['date'] as String: DayMode.fromString(row['mode'] as String?),
    };
  }
}
