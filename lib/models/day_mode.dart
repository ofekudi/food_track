import '../constants/strings.dart';

/// How a given day is meant to be eaten.
///
/// The plan is explicit that restaurants and events are part of the process,
/// not cheats — so an [event] day changes the shape of the slots and the copy
/// around them, never the scoring.
enum DayMode {
  normal,
  event;

  String get displayName =>
      this == DayMode.event ? AppStrings.modeEvent : AppStrings.modeNormal;

  static DayMode fromString(String? value) => DayMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => DayMode.normal,
      );
}
