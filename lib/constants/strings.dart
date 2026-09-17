/// App-wide string constants for easy localization.
/// To add translations, replace these with a localization system like
/// flutter_localizations.
class AppStrings {
  // App
  static const appName = 'Slots';

  // Slots
  static const slotBreakfast = 'Breakfast';
  static const slotLunch = 'Lunch';
  static const slotSnack = 'Snack';
  static const slotDinner = 'Dinner';
  static const slotExtra = 'Extra';

  static const addExtra = 'Add an extra';

  // Day modes
  static const modeNormal = 'Normal day';
  static const modeEvent = 'Event day';
  static const eventModeTooltip = 'Eating out today';

  // Plate composition
  static const plateProtein = 'Protein';
  static const plateCarb = 'Carb';
  static const plateFat = 'Fat';
  static const plateVeg = 'Veg';
  static const plateTreat = 'Treat';

  // Week strip

  // Log sheet
  static const logHint = 'e.g. "3 eggs, whey, yogurt"';

  // Preferences
  static const preferences = 'Preferences';
  static const dailyCalories = 'Daily calories';
  static const dailyCaloriesSubtitle = 'Roughly how big your day is';
  static const derivedFromTarget = 'Per meal';
  static const caloriesAreReference =
      'A reference for the shape of the day, not a count of what you eat. '
      'The split follows the plan\'s proportions.';

  /// Reference figure on a slot title, e.g. "470 cal".
  static String calories(int value) => '$value cal';
  static const eventDays = 'Event days';
  static const eventDaysSubtitle =
      'Days that start as an event day. Any day can still be switched by hand.';
  static const save = 'Save';
  static const done = 'Done';

  static const cancel = 'Cancel';
  static const delete = 'Delete';
  static const edit = 'Edit';
  static const addToSlot = 'Add';
  static const portionsTooltip = 'What the portions mean';
  static const entryDeleted = 'Deleted';

  // Date navigation
  static const previousDay = 'Previous day';
  static const nextDay = 'Next day';
  static const cannotGoBeyondToday = 'Cannot go beyond today';
}
