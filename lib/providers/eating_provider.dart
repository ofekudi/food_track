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
}
