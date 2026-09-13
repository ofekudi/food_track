import '../models/day_mode.dart';
import '../models/meal_slot.dart';

/// The plan's own rules, surfaced where they apply rather than in a document
/// you'd never reopen. Each one is a single line attached to a slot, a mode,
/// or a moment.
class AppInsights {
  /// Shown right after logging something outside the slots. This is the plan's
  /// most valuable rule: the damage isn't the extra, it's the day you write
  /// off afterwards.
  static const noOffsetting =
      "No offsetting — don't skip your next slot to make up for it.";

  /// Shown when a day is switched to event mode.
  static const eventDay =
      'Eating out is part of the plan. Combine slots to bank room for it.';

  /// One line under a slot, when it has something to say. The snack says it
  /// already through its plate ("1 protein · 1 treat") and its chips.
  static String? forSlot(MealSlot slot, DayMode mode) {
    if (slot == MealSlot.dinner) {
      if (mode == DayMode.event) {
        return 'Wait 5 minutes before seconds — then lean protein and veg only.';
      }
      return "Plate it smaller now — it's easier than stopping halfway.";
    }
    return null;
  }

  /// The plan's ~150 calorie treat, for the snack slot.
  static const _treatIdeas = ['Chocolate', 'Bamba', 'Fruit', 'Beer'];

  static const _breakfastIdeas = ['Shake', 'Yogurt'];

  static const _lunchIdeas = ['Chicken Salad', 'Schnitzels'];

  static const _dinnerIdeas = [
    'Home Special',
    'Shake',
    'Yogurt',
    'Bolognese',
  ];

  /// Starter chips for a slot, for before your own history fills in. Kept to
  /// one or two words so the row doesn't wrap.
  static List<String> ideasFor(MealSlot slot) {
    switch (slot) {
      case MealSlot.breakfast:
        return _breakfastIdeas;
      case MealSlot.snack:
        return _treatIdeas;
      case MealSlot.dinner:
        return _dinnerIdeas;
      case MealSlot.lunch:
        return _lunchIdeas;
      case MealSlot.extras:
        return const [];
    }
  }
}
