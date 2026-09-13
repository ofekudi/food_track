import 'day_mode.dart';
import 'meal_slot.dart';

/// One day boiled down for the week strip.
class DaySummary {
  final DateTime date;
  final Set<MealSlot> filledSlots;
  final int extrasCount;
  final DayMode mode;

  const DaySummary({
    required this.date,
    required this.filledSlots,
    required this.extrasCount,
    required this.mode,
  });

  bool get hasAnything => filledSlots.isNotEmpty || extrasCount > 0;

  /// A clean day is one you actually tracked and ate entirely inside the
  /// slots. A day with nothing logged is not clean — otherwise not using the
  /// app would look like success.
  bool get isClean => filledSlots.isNotEmpty && extrasCount == 0;
}
