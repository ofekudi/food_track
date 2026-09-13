import 'package:flutter/foundation.dart';
import '../db_helper.dart';
import '../models/day_mode.dart';
import '../models/day_summary.dart';
import '../models/day_timeline.dart';
import '../models/entry.dart';
import '../models/meal_slot.dart';

/// How many days the week strip shows.
const int kWeekLength = 7;

class DayProvider with ChangeNotifier {
  final DBHelper _db = DBHelper();

  DateTime _selectedDate = _startOfDay(DateTime.now());
  List<Entry> _entries = [];
  DayMode _mode = DayMode.normal;
  List<DaySummary> _week = [];

  DateTime get selectedDate => _selectedDate;
  DayMode get mode => _mode;
  List<DaySummary> get week => _week;

  bool get isToday => _isSameDay(_selectedDate, DateTime.now());

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> load() async {
    await Future.wait([_loadDay(), _loadWeek()]);
    notifyListeners();
  }

  Future<void> _loadDay() async {
    _entries = await _db.entriesForDate(_selectedDate);
    _mode = await _db.modeForDate(_selectedDate);
  }

  Future<void> _loadWeek() async {
    final today = _startOfDay(DateTime.now());
    final from = today.subtract(const Duration(days: kWeekLength - 1));
    final entries = await _db.entriesSince(from);
    final modes = await _db.modesSince(from);

    final byDay = <String, List<Entry>>{};
    for (final entry in entries) {
      byDay.putIfAbsent(entry.date, () => []).add(entry);
    }

    _week = List.generate(kWeekLength, (i) {
      final date = from.add(Duration(days: i));
      final key = formatDay(date);
      final dayEntries = byDay[key] ?? const <Entry>[];
      return DaySummary(
        date: date,
        filledSlots: dayEntries
            .where((e) => !e.slot.isExtra)
            .map((e) => e.slot)
            .toSet(),
        extrasCount: dayEntries.where((e) => e.slot.isExtra).length,
        mode: modes[key] ?? DayMode.normal,
      );
    });
  }

  /// The selected day laid out in the order it happened.
  List<DayItem> get timeline {
    final items = <DayItem>[
      for (final slot in MealSlot.meals)
        SlotItem(slot, _entries.where((e) => e.slot == slot).toList()),
      for (final entry in _entries.where((e) => e.slot.isExtra))
        ExtraItem(entry),
    ];
    items.sort((a, b) => a.sortMinutes.compareTo(b.sortMinutes));
    return items;
  }

  int get extrasToday => _entries.where((e) => e.slot.isExtra).length;

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = _startOfDay(date);
    await _loadDay();
    notifyListeners();
  }

  Future<void> setMode(DayMode mode) async {
    await _db.setModeForDate(_selectedDate, mode);
    _mode = mode;
    await _loadWeek();
    notifyListeners();
  }

  Future<void> addEntry({
    required MealSlot slot,
    required String text,
  }) async {
    await _db.addEntry(date: _selectedDate, slot: slot, text: text);
    await load();
  }

  Future<void> updateEntryText(String id, String text) async {
    await _db.updateEntryText(id, text);
    await load();
  }

  Future<void> deleteEntry(String id) async {
    await _db.deleteEntry(id);
    await load();
  }

}
