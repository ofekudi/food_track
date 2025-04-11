import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import material for TimeOfDay
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _breakfastLimitKey = 'dailyLimit_Breakfast';
  static const String _lunchLimitKey = 'dailyLimit_Lunch';
  static const String _dinnerLimitKey = 'dailyLimit_Dinner';
  static const String _snackLimitKey = 'dailyLimit_Snack';
  static const String _coffeeLimitKey = 'dailyLimit_Coffee';

  // New Keys for Kitchen Closed Time
  static const String _kitchenClosedHourKey = 'kitchenClosedHour';
  static const String _kitchenClosedMinuteKey = 'kitchenClosedMinute';

  // New Key for Banner Title
  static const String _stopEatingTitleKey = 'stopEatingTitle';
  static const String _stopEatingEnabledKey =
      'stopEatingEnabled'; // Key to store enabled state

  // Default Title
  static const String defaultStopEatingTitle = "Let It Settle";

  Map<String, int> _dailyLimits = {
    'Breakfast': 0,
    'Lunch': 0,
    'Dinner': 0,
    'Snack': 0,
    'Coffee': 0,
  };

  TimeOfDay? _kitchenClosedTime; // Stores the time preference
  String _stopEatingTitle =
      defaultStopEatingTitle; // Stores the selected banner title
  bool _stopEatingEnabled = false; // Stores if the feature is enabled

  Map<String, int> get dailyLimits => _dailyLimits;
  TimeOfDay? get kitchenClosedTime => _stopEatingEnabled
      ? _kitchenClosedTime
      : null; // Return time only if enabled
  String get stopEatingTitle => _stopEatingTitle;
  bool get stopEatingEnabled => _stopEatingEnabled;

  // List of available titles
  final List<String> availableStopEatingTitles = const [
    "Let It Settle",
    "Hold the Craving",
    "Suck It In",
    "Kitchen's Closed",
    "Wait for Tomorrow"
  ];

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Daily Limits
    _dailyLimits = {
      'Breakfast': prefs.getInt(_breakfastLimitKey) ?? 0,
      'Lunch': prefs.getInt(_lunchLimitKey) ?? 0,
      'Dinner': prefs.getInt(_dinnerLimitKey) ?? 0,
      'Snack': prefs.getInt(_snackLimitKey) ?? 0,
      'Coffee': prefs.getInt(_coffeeLimitKey) ?? 0,
    };

    // Load Stop Eating Enabled State
    _stopEatingEnabled = prefs.getBool(_stopEatingEnabledKey) ?? false;

    // Load Kitchen Closed Time (only relevant if enabled, but load anyway)
    final hour = prefs.getInt(_kitchenClosedHourKey);
    final minute = prefs.getInt(_kitchenClosedMinuteKey);
    if (hour != null && minute != null) {
      _kitchenClosedTime = TimeOfDay(hour: hour, minute: minute);
    } else {
      _kitchenClosedTime = null;
    }

    // Load Stop Eating Title
    _stopEatingTitle =
        prefs.getString(_stopEatingTitleKey) ?? defaultStopEatingTitle;
    // Ensure the loaded title is valid, otherwise reset to default
    if (!availableStopEatingTitles.contains(_stopEatingTitle)) {
      _stopEatingTitle = defaultStopEatingTitle;
      // Optionally save the default back if it was invalid
      await prefs.setString(_stopEatingTitleKey, _stopEatingTitle);
    }

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
    await _loadSettings(); // Reload all settings
  }

  // Updated method to set the kitchen closed time (now only sets the time internally)
  Future<void> setKitchenClosedTime(TimeOfDay? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time != null) {
      await prefs.setInt(_kitchenClosedHourKey, time.hour);
      await prefs.setInt(_kitchenClosedMinuteKey, time.minute);
    } else {
      await prefs.remove(_kitchenClosedHourKey);
      await prefs.remove(_kitchenClosedMinuteKey);
    }
    // No need to reload settings here, will be handled by enable/disable
    _kitchenClosedTime = time; // Update local state
    notifyListeners(); // Notify about potential time change
  }

  // New method to set the stop eating banner title
  Future<void> setStopEatingTitle(String title) async {
    if (!availableStopEatingTitles.contains(title)) {
      title = defaultStopEatingTitle; // Use default if invalid
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stopEatingTitleKey, title);
    _stopEatingTitle = title; // Update local state
    notifyListeners();
  }

  // New method to enable/disable the stop eating feature
  Future<void> setStopEatingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stopEatingEnabledKey, enabled);
    _stopEatingEnabled = enabled; // Update local state
    // Optionally clear the time if disabling
    // if (!enabled) {
    //   await setKitchenClosedTime(null);
    // }
    notifyListeners();
  }

  int getDailyLimitForMeal(String mealType) {
    return _dailyLimits[mealType] ?? 0;
  }
}
