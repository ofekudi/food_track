import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meal_slot.dart';

/// The only thing the app lets you configure: roughly how big your day is.
///
/// Per-slot figures are derived from this so the plan's proportions hold
/// whatever total you set — there's no way to end up with four numbers that
/// don't add up.
class SettingsProvider with ChangeNotifier {
  static const String _dailyCaloriesKey = 'dailyCalories';

  static const int defaultDailyCalories = MealSlot.planDailyCalories;
  static const int minDailyCalories = 1200;
  static const int maxDailyCalories = 3600;
  static const int step = 50;

  int _dailyCalories = defaultDailyCalories;

  int get dailyCalories => _dailyCalories;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyCalories = (prefs.getInt(_dailyCaloriesKey) ?? defaultDailyCalories)
        .clamp(minDailyCalories, maxDailyCalories);
    notifyListeners();
  }

  Future<void> setDailyCalories(int value) async {
    final clamped = value.clamp(minDailyCalories, maxDailyCalories);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyCaloriesKey, clamped);
    _dailyCalories = clamped;
    notifyListeners();
  }
}
