import 'package:flutter/foundation.dart';
import '../db_helper.dart';
import '../models/eating_log.dart';

class EatingProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<EatingLog> _eatingLogs = [];
  DateTime _selectedDate = DateTime.now();

  // Every entry, for the 7-day trend and the streak/target counters
  List<EatingLog> _allEatingLogs = [];
  bool _hasLoadedAllLogs = false;

  List<EatingLog> get eatingLogs => _eatingLogs;
  DateTime get selectedDate => _selectedDate;

  Future<void> loadEatingLogs() async {
    final logsData = await _dbHelper.getEatingLogsForDate(_selectedDate);
    _eatingLogs = logsData.map((e) => EatingLog.fromMap(e)).toList();
    notifyListeners();

    // Load all logs for analytics if not already loaded
    if (!_hasLoadedAllLogs) {
      _loadAllLogs();
    }
  }

  Future<void> _loadAllLogs() async {
    final allLogsData = await _dbHelper.getAllEatingLogs();
    _allEatingLogs = allLogsData.map((e) => EatingLog.fromMap(e)).toList();
    _hasLoadedAllLogs = true;
    notifyListeners();
  }

  Future<void> addEatingLog({
    required String description,
    required int hungerLevel,
    required EatingReason reason,
    DateTime? entryDate,
  }) async {
    try {
      await _dbHelper.addEatingLog(
        description: description,
        hungerLevel: hungerLevel,
        reason: reason,
        entryDate: entryDate ?? _selectedDate,
      );
      // Reset the loaded flag to refresh analytics
      _hasLoadedAllLogs = false;
      await loadEatingLogs();
    } catch (e) {
      if (kDebugMode) {
        print("Error adding eating log: $e");
      }
    }
  }

  Future<void> addMiss({
    required String description,
    DateTime? entryDate,
  }) async {
    try {
      await _dbHelper.addMiss(
        description: description,
        entryDate: entryDate ?? _selectedDate,
      );
      // Reset the loaded flag to refresh analytics
      _hasLoadedAllLogs = false;
      await loadEatingLogs();
    } catch (e) {
      if (kDebugMode) {
        print("Error adding miss: $e");
      }
    }
  }

  Future<void> deleteEatingLog(String id) async {
    await _dbHelper.deleteEatingLog(id);
    _hasLoadedAllLogs = false;
    await loadEatingLogs();
  }

  Future<void> updateEatingLog(EatingLog log) async {
    await _dbHelper.updateEatingLog(log);
    _hasLoadedAllLogs = false;
    await loadEatingLogs();
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await loadEatingLogs();
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Count of "miss" entries in the last 7 days (today + previous 6).
  int get last7DaysMissCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cutoff = today.subtract(const Duration(days: 6));
    return _allEatingLogs.where((log) {
      if (!log.isMiss) return false;
      final d =
          DateTime(log.entryDate.year, log.entryDate.month, log.entryDate.day);
      return !d.isBefore(cutoff) && !d.isAfter(today);
    }).length;
  }

  /// Per-day counts of the entries matching [include] over the last 7 days,
  /// oldest first. Index 6 is today, index 0 is 6 days ago — ready to plot
  /// left-to-right as a trend.
  List<int> _last7DaysCountsByDay(bool Function(EatingLog) include) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = List<int>.filled(7, 0);
    for (final log in _allEatingLogs) {
      if (!include(log)) continue;
      final d =
          DateTime(log.entryDate.year, log.entryDate.month, log.entryDate.day);
      final diff = today.difference(d).inDays;
      if (diff >= 0 && diff < 7) {
        counts[6 - diff] += 1;
      }
    }
    return counts;
  }

  /// Miss counts for the last 7 days, oldest first.
  List<int> get last7DaysMissCountsByDay =>
      _last7DaysCountsByDay((log) => log.isMiss);

  /// Recording counts for the last 7 days, oldest first. Misses count too —
  /// they're still an eating occasion, just logged after the fact — but drinks
  /// don't.
  List<int> get last7DaysRecordingCountsByDay =>
      _last7DaysCountsByDay((log) => log.countsTowardTarget);

  /// What today has spent of the daily budget: misses included, drinks not.
  /// Unlike [todayLogCount] this always means *today*, never the date the user
  /// is browsing.
  int get todayRecordingCount {
    final now = DateTime.now();
    final key = _dayKey(DateTime(now.year, now.month, now.day));
    return _allEatingLogs
        .where((log) => log.countsTowardTarget && _dayKey(log.entryDate) == key)
        .length;
  }

  /// Consecutive recent days that stayed on target: at least one recording and
  /// no more than [target]. Today doesn't break the streak while it's still
  /// pending (nothing logged yet, or still within target); going over ends it.
  int daysOnTargetStreak(int target) {
    final Map<String, int> countByDay = {};
    for (final log in _allEatingLogs) {
      if (!log.countsTowardTarget) continue;
      final key = _dayKey(log.entryDate);
      countByDay[key] = (countByDay[key] ?? 0) + 1;
    }

    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    int streak = 0;
    bool isToday = true;
    while (true) {
      final count = countByDay[_dayKey(day)] ?? 0;
      if (count > 0 && count <= target) {
        streak++;
      } else if (isToday && count <= target) {
        // Today is still pending — nothing logged yet, but nothing over either.
      } else {
        break;
      }
      day = day.subtract(const Duration(days: 1));
      isToday = false;
    }
    return streak;
  }

  /// Consecutive recent days that qualify as "miss-free": at least 3 non-miss
  /// logs and zero misses. Today doesn't break the streak while it's still
  /// pending (no miss yet but fewer than 3 logs); a miss today ends it.
  int get daysWithoutMissStreak {
    final Map<String, int> nonMissByDay = {};
    final Map<String, int> missByDay = {};
    for (final log in _allEatingLogs) {
      final key = _dayKey(log.entryDate);
      if (log.isMiss) {
        missByDay[key] = (missByDay[key] ?? 0) + 1;
      } else {
        nonMissByDay[key] = (nonMissByDay[key] ?? 0) + 1;
      }
    }

    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    int streak = 0;
    bool isToday = true;
    while (true) {
      final key = _dayKey(day);
      final nonMiss = nonMissByDay[key] ?? 0;
      final misses = missByDay[key] ?? 0;
      final qualifies = nonMiss >= 3 && misses == 0;
      if (qualifies) {
        streak++;
      } else if (isToday && misses == 0) {
        // Today is still pending — don't break the streak yet.
      } else {
        break;
      }
      day = day.subtract(const Duration(days: 1));
      isToday = false;
    }
    return streak;
  }
}
