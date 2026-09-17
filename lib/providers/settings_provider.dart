import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/day_mode.dart';
import '../models/meal_slot.dart';

/// What the app lets you configure: roughly how big your day is, and which
/// weekdays start out as event days.
///
/// Per-slot figures are derived from the daily total so the plan's
/// proportions hold whatever total you set — there's no way to end up with
/// four numbers that don't add up.
class SettingsProvider with ChangeNotifier {
  static const String _dailyCaloriesKey = 'dailyCalories';
  static const String _eventWeekdaysKey = 'eventWeekdays';

  static const int defaultDailyCalories = MealSlot.planDailyCalories;
  static const int minDailyCalories = 1200;
  static const int maxDailyCalories = 3600;
  static const int step = 50;

  int _dailyCalories = defaultDailyCalories;

  /// Weekdays as [DateTime.weekday] values (Monday is 1, Sunday is 7).
  Set<int> _eventWeekdays = const {};

  int get dailyCalories => _dailyCalories;
  Set<int> get eventWeekdays => Set.unmodifiable(_eventWeekdays);

  SettingsProvider() {
    _load();
  }

  /// How a day starts out before you've said anything about it. A Friday you
  /// switch back to normal stays normal — this only fills the gap.
  DayMode defaultModeFor(DateTime date) =>
      _eventWeekdays.contains(date.weekday) ? DayMode.event : DayMode.normal;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyCalories = (prefs.getInt(_dailyCaloriesKey) ?? defaultDailyCalories)
        .clamp(minDailyCalories, maxDailyCalories);
    _eventWeekdays = (prefs.getStringList(_eventWeekdaysKey) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .where((d) => d >= DateTime.monday && d <= DateTime.sunday)
        .toSet();
    notifyListeners();
  }

  Future<void> setDailyCalories(int value) async {
    final clamped = value.clamp(minDailyCalories, maxDailyCalories);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyCaloriesKey, clamped);
    _dailyCalories = clamped;
    notifyListeners();
  }

  Future<void> setEventWeekday(int weekday, bool isEvent) async {
    final next = Set<int>.of(_eventWeekdays);
    if (isEvent) {
      next.add(weekday);
    } else {
      next.remove(weekday);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _eventWeekdaysKey,
      next.map((d) => '$d').toList()..sort(),
    );
    _eventWeekdays = next;
    notifyListeners();
  }
}
