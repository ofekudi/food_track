import 'package:flutter/foundation.dart';
import '../db_helper.dart';
import '../models/eating_log.dart';

class EatingProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<EatingLog> _eatingLogs = [];
  DateTime _selectedDate = DateTime.now();

  // All entries for analytics
  List<EatingLog> _allEatingLogs = [];
  bool _hasLoadedAllLogs = false;

  List<EatingLog> get eatingLogs => _eatingLogs;
  DateTime get selectedDate => _selectedDate;
  List<EatingLog> get allEatingLogs => _allEatingLogs;

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

  /// Get today's logs count
  int get todayLogCount => _eatingLogs.length;

  /// Get the reason distribution for current day
  Map<EatingReason, int> get todayReasonDistribution {
    Map<EatingReason, int> distribution = {};
    for (var reason in EatingReason.values) {
      distribution[reason] = 0;
    }
    for (var log in _eatingLogs) {
      distribution[log.reason] = (distribution[log.reason] ?? 0) + 1;
    }
    return distribution;
  }

  /// Get average hunger level for current day
  double get todayAverageHunger {
    if (_eatingLogs.isEmpty) return 0;
    final total = _eatingLogs.fold<int>(0, (sum, log) => sum + log.hungerLevel);
    return total / _eatingLogs.length;
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
