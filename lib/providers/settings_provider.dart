import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // Keys for Kitchen Closed Time
  static const String _kitchenClosedHourKey = 'kitchenClosedHour';
  static const String _kitchenClosedMinuteKey = 'kitchenClosedMinute';

  // Key for Banner Title
  static const String _stopEatingTitleKey = 'stopEatingTitle';
  static const String _stopEatingEnabledKey = 'stopEatingEnabled';

  // Key for the mindful pause (spinner) duration on the log CTA
  static const String _pauseSecondsKey = 'mindfulPauseSeconds';

  // Key for the daily recordings target shown on the home trend chart
  static const String _recordingsTargetKey = 'dailyRecordingsTarget';

  // Default Title
  static const String defaultStopEatingTitle = "Late Snack Detected";

  // Default mindful pause duration before the log CTA becomes tappable.
  static const int defaultPauseSeconds = 5;
  static const int maxPauseSeconds = 30;

  // Default number of eating recordings to aim for each day.
  static const int defaultRecordingsTarget = 3;
  static const int minRecordingsTarget = 1;
  static const int maxRecordingsTarget = 10;

  TimeOfDay? _kitchenClosedTime;
  String _stopEatingTitle = defaultStopEatingTitle;
  bool _stopEatingEnabled = false;
  int _pauseSeconds = defaultPauseSeconds;
  int _recordingsTarget = defaultRecordingsTarget;
  Future<void>? _loadFuture;

  TimeOfDay? get kitchenClosedTime => _stopEatingEnabled ? _kitchenClosedTime : null;
  String get stopEatingTitle => _stopEatingTitle;
  bool get stopEatingEnabled => _stopEatingEnabled;
  int get pauseSeconds => _pauseSeconds;
  int get recordingsTarget => _recordingsTarget;

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

    // Load mindful pause duration, clamped to a sane range.
    _pauseSeconds =
        (prefs.getInt(_pauseSecondsKey) ?? defaultPauseSeconds).clamp(0, maxPauseSeconds);

    // Load the daily recordings target, clamped to a sane range.
    _recordingsTarget = (prefs.getInt(_recordingsTargetKey) ?? defaultRecordingsTarget)
        .clamp(minRecordingsTarget, maxRecordingsTarget);

    notifyListeners();
  }

  Future<void> setRecordingsTarget(int target) async {
    final clamped = target.clamp(minRecordingsTarget, maxRecordingsTarget);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_recordingsTargetKey, clamped);
    _recordingsTarget = clamped;
    notifyListeners();
  }

  Future<void> setPauseSeconds(int seconds) async {
    final clamped = seconds.clamp(0, maxPauseSeconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pauseSecondsKey, clamped);
    _pauseSeconds = clamped;
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
