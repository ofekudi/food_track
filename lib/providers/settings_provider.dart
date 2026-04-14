import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // Keys for Kitchen Closed Time
  static const String _kitchenClosedHourKey = 'kitchenClosedHour';
  static const String _kitchenClosedMinuteKey = 'kitchenClosedMinute';

  // Key for Banner Title
  static const String _stopEatingTitleKey = 'stopEatingTitle';
  static const String _stopEatingEnabledKey = 'stopEatingEnabled';

  // Default Title
  static const String defaultStopEatingTitle = "Late Snack Detected";

  TimeOfDay? _kitchenClosedTime;
  String _stopEatingTitle = defaultStopEatingTitle;
  bool _stopEatingEnabled = false;
  Future<void>? _loadFuture;

  TimeOfDay? get kitchenClosedTime => _stopEatingEnabled ? _kitchenClosedTime : null;
  String get stopEatingTitle => _stopEatingTitle;
  bool get stopEatingEnabled => _stopEatingEnabled;

  // List of available titles - updated for mindful eating
  final List<String> availableStopEatingTitles = const [
    "Late Snack Detected",
    "Kitchen's Closed",
    "Time to Rest",
    "Nighttime Check-in",
    "Pause & Reflect",
  ];

  SettingsProvider() {
    _loadFuture = _loadSettings();
  }

  Future<void> ensureLoaded() async {
    await (_loadFuture ??= _loadSettings());
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Stop Eating Enabled State
    _stopEatingEnabled = prefs.getBool(_stopEatingEnabledKey) ?? false;

    // Load Kitchen Closed Time
    final hour = prefs.getInt(_kitchenClosedHourKey);
    final minute = prefs.getInt(_kitchenClosedMinuteKey);
    if (hour != null && minute != null) {
      _kitchenClosedTime = TimeOfDay(hour: hour, minute: minute);
    } else {
      _kitchenClosedTime = null;
    }

    // Load Stop Eating Title
    _stopEatingTitle = prefs.getString(_stopEatingTitleKey) ?? defaultStopEatingTitle;
    // Ensure the loaded title is valid
    if (!availableStopEatingTitles.contains(_stopEatingTitle)) {
      _stopEatingTitle = defaultStopEatingTitle;
      await prefs.setString(_stopEatingTitleKey, _stopEatingTitle);
    }

    notifyListeners();
  }

  Future<void> setKitchenClosedTime(TimeOfDay? time) async {
    final prefs = await SharedPreferences.getInstance();
    if (time != null) {
      await prefs.setInt(_kitchenClosedHourKey, time.hour);
      await prefs.setInt(_kitchenClosedMinuteKey, time.minute);
    } else {
      await prefs.remove(_kitchenClosedHourKey);
      await prefs.remove(_kitchenClosedMinuteKey);
    }
    _kitchenClosedTime = time;
    notifyListeners();
  }

  Future<void> setStopEatingTitle(String title) async {
    if (!availableStopEatingTitles.contains(title)) {
      title = defaultStopEatingTitle;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stopEatingTitleKey, title);
    _stopEatingTitle = title;
    notifyListeners();
  }

  Future<void> setStopEatingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stopEatingEnabledKey, enabled);
    _stopEatingEnabled = enabled;
    notifyListeners();
  }
}
