import 'entry.dart';
import 'meal_slot.dart';

/// One row on the home screen. The day is laid out in the order it actually
/// happened, so an extra eaten at 16:00 sits between lunch and dinner rather
/// than in a bucket at the bottom — which is the whole point of showing it.
sealed class DayItem {
  int get sortMinutes;
}

/// One of the four meals, filled or not.
class SlotItem extends DayItem {
  final MealSlot slot;
  final List<Entry> entries;

  SlotItem(this.slot, this.entries);

  bool get isFilled => entries.isNotEmpty;

  /// An unfilled slot holds its place at the time it's usually eaten.
  @override
  int get sortMinutes =>
      isFilled ? entries.first.minutesOfDay : slot.defaultMinutes;
}

/// A single thing eaten outside the slots. One row each, deliberately: three
/// extras should make the day look three rows longer.
class ExtraItem extends DayItem {
  final Entry entry;

  ExtraItem(this.entry);

  @override
  int get sortMinutes => entry.minutesOfDay;
}
