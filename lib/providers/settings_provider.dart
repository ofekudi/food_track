import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _breakfastLimitKey = 'dailyLimit_Breakfast';
  static const String _lunchLimitKey = 'dailyLimit_Lunch';
  static const String _dinnerLimitKey = 'dailyLimit_Dinner';
  static const String _snackLimitKey = 'dailyLimit_Snack';
  static const String _coffeeLimitKey = 'dailyLimit_Coffee';

  Map<String, int> _dailyLimits = {
    'Breakfast': 0,
    'Lunch': 0,
    'Dinner': 0,
    'Snack': 0,
    'Coffee': 0,
  };

  Map<String, int> get dailyLimits => _dailyLimits;

  SettingsProvider() {
    _loadDailyLimits();
  }

  Future<void> _loadDailyLimits() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyLimits = {
      'Breakfast': prefs.getInt(_breakfastLimitKey) ?? 0,
      'Lunch': prefs.getInt(_lunchLimitKey) ?? 0,
      'Dinner': prefs.getInt(_dinnerLimitKey) ?? 0,
      'Snack': prefs.getInt(_snackLimitKey) ?? 0,
      'Coffee': prefs.getInt(_coffeeLimitKey) ?? 0,
    };
    notifyListeners();
  }

  Future<void> setDailyLimit(String mealType, int limit) async {
    if (!_dailyLimits.containsKey(mealType)) return;

    final prefs = await SharedPreferences.getInstance();
    String key;
    switch (mealType) {
      case 'Breakfast':
        key = _breakfastLimitKey;
        break;
      case 'Lunch':
        key = _lunchLimitKey;
        break;
      case 'Dinner':
        key = _dinnerLimitKey;
        break;
      case 'Snack':
        key = _snackLimitKey;
        break;
      case 'Coffee':
        key = _coffeeLimitKey;
        break;
      default:
        return; // Should not happen
    }

    await prefs.setInt(key, limit < 0 ? 0 : limit); // Store non-negative limits
    await _loadDailyLimits(); // Reload to update state and notify listeners
  }

  int getDailyLimitForMeal(String mealType) {
    return _dailyLimits[mealType] ?? 0;
  }
}
