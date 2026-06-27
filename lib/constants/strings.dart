/// App-wide string constants for easy localization
/// To add translations, replace these with a localization system like flutter_localizations
class AppStrings {
  // App
  static const appName = 'Mindful Eating';

  // Order priming ("log before you eat")
  static const orderTagline = 'Log → Eat'; // home AppBar subtitle
  static const stepLog = 'Log';
  static const stepBreathe = 'Breathe';
  static const stepEat = 'Eat';

  // Hunger levels
  static const hungerQuestion = 'How hungry are you?';
  static const hungerHint = 'Tap a number from 1 (not hungry) to 5 (very hungry)';
  static const notHungry = 'Not hungry';
  static const veryHungry = 'Very hungry';

  // Reasons
  static const reasonQuestion = 'Why are you eating?';
  static const reasonHungry = 'Hungry';
  static const reasonBored = 'Bored';
  static const reasonCraving = 'Craving';
  static const reasonSocial = 'Social';
  static const reasonHabit = 'Habit';
  static const backToHunger = 'Back to hunger';

  // Description
  static const descriptionQuestion = 'What are you eating?';
  static const descriptionHint = 'Add a row for each food or drink';
  static const descriptionPlaceholder = 'e.g., "3 schnitzels" or "handful of chips"';
  static const amountPlaceholder = 'Amount'; // e.g. "one glass", "4 items"
  static const foodPlaceholder = 'Food'; // e.g. "chips", "water"
  static const addItem = 'Add item';
  static const removeItem = 'Remove item';

  // Intervention
  static const interventionTitle = 'Not very hungry?';
  static const interventionSubtitle = "That's okay! Here are some alternatives you might try:";
  static const logAnyway = 'Log anyway';
  static const maybeLater = 'Maybe later';

  // Suggestions
  static const suggestionWater = 'Drink a glass of water';
  static const suggestionWait = 'Wait 10 minutes';
  static const suggestionWalk = 'Take a short walk';
  static const suggestionBreathe = 'Take 3 deep breaths';

  // Home screen
  static const noEntriesTitle = 'No entries for this day';
  static const noEntriesSubtitle = 'Tap + to log what you eat';
  static const hunger = 'Hunger';
  static const reason = 'Reason';

  // Miss logging + home stat boxes
  static const logMiss = 'Forgot to log it';
  static const missDialogTitle = 'Log a missed meal';
  static const missDialogHint = 'What did you eat?';
  static const loggedAsMiss = 'Logged as a miss';
  static const cancel = 'Cancel';
  static const last7DaysMisses = '7-Day Misses';
  static const missFreeStreak = 'Miss-Free Streak';
  static const last7DaysTrend = 'Misses per day';

  // Kitchen closed
  static const kitchenClosedQuestion = 'Are you hungry or just looking for a snack?';
  static const tryTheseInstead = 'Try These Instead';
  static const gotIt = 'Got It';

  // Analytics
  static const weeklyInsights = 'Insights';
  static const noDataTitle = 'No data for this period';
  static const noDataSubtitle = 'Start logging your meals to see insights';
  static const totalEntries = 'Total Entries';
  static const avgHunger = 'Avg Hunger';
  static const lateNight = 'Late Night';
  static const whyYouEat = 'Why You Eat';
  static const hungerPatterns = 'Hunger Patterns';
  static const whenYouEat = 'When You Eat';
  static const eatingTimes = 'Eating times';
  static const hungerLevels = 'Hunger levels';
  static const byDayOfWeek = 'By day of week:';
  static const lowHungerWarning = '% of eating happened at low hunger (1-2)';
  static const ateWhenNotHungry = 'You ate when not hungry %d times this week';

  // Entry actions
  static const edit = 'Edit';
  static const delete = 'Delete';
  static const save = 'Save';
  static const done = 'Done';
  static const back = 'Back';
  static const entryDeleted = 'Entry deleted';
  static const logEating = 'Log Eating';
  static const editEntry = 'Edit Entry';

  // Preferences
  static const preferences = 'Preferences';
  static const kitchenClosed = 'Kitchen Closed';
  static const kitchenClosedSubtitle = 'Configure late-night reminder';
  static const pauseTimer = 'Mindful pause';
  static const pauseTimerSubtitle = 'Seconds to wait before you can log';
  static const pauseTimerDialogTitle = 'Pause before logging';
  static const seconds = 'seconds';
  static const off = 'Off';
  static const enabled = 'Enabled';
  static const showReminderSubtitle = 'Show reminder after this time';
  static const time = 'Time';
  static const reminderTitle = 'Reminder Title';
  static const notSet = 'Not set';
  static const kitchenClosedDescription =
      'When enabled, a gentle reminder will appear if you open the app after the set time, asking if you\'re truly hungry or just snacking out of habit.';

  // Time ranges
  static const last7Days = 'Last 7 days';
  static const last14Days = 'Last 14 days';
  static const last30Days = 'Last 30 days';

  // Days of week
  static const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Mindfulness timer
  static const mindfulnessPausing = 'Taking a moment to pause...';
  static const mindfulnessMessages = [
    'Take a moment to notice how you\'re feeling...',
    'Are you truly hungry, or is this something else?',
    'Pause and check in with your body...',
    'What do you really need right now?',
    'Breathe and observe your thoughts...',
    'Consider drinking water first',
    'Avoid overeating to maintain healthy fat levels',
    'Try setting a 20-minute timer before eating more',
  ];
}
