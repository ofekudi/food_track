import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/eating_provider.dart';
import '../providers/settings_provider.dart';
import '../models/eating_log.dart';
import '../constants/strings.dart';
import '../widgets/hunger_indicator.dart';
import '../widgets/reason_chip.dart';
import 'add_entry_screen.dart';
import 'mindfulness_timer_screen.dart';
import 'meal_analytics_screen.dart';
import 'preferences_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _dayResetMinutes = 5 * 60;

  bool _shouldShowKitchenClosedReminder() {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);
    if (!settingsProvider.stopEatingEnabled) return false;

    final kitchenClosedTime = settingsProvider.kitchenClosedTime;
    if (kitchenClosedTime == null) return false;

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final closedMinutes = kitchenClosedTime.hour * 60 + kitchenClosedTime.minute;

    // Keep the "kitchen closed" window active overnight and reset it at 5:00 AM.
    if (closedMinutes < _dayResetMinutes) {
      return nowMinutes >= closedMinutes && nowMinutes < _dayResetMinutes;
    }

    return nowMinutes >= closedMinutes || nowMinutes < _dayResetMinutes;
  }

  Future<void> _startAddFlow() async {
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.ensureLoaded();
    if (!mounted) return;

    final selectedDate = context.read<EatingProvider>().selectedDate;

    if (_shouldShowKitchenClosedReminder()) {
      _showKitchenClosedDialog(settingsProvider.stopEatingTitle);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MindfulnessTimerScreen(targetDate: selectedDate),
      ),
    );
  }

  Future<void> _logMiss() async {
    final eatingProvider = context.read<EatingProvider>();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => const _MissEntryDialog(),
    );
    if (text != null && text.trim().isNotEmpty) {
      await eatingProvider.addMiss(
        description: text.trim(),
        entryDate: eatingProvider.selectedDate,
      );
    }
  }

  void _showKitchenClosedDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.bedtime_outlined,
            color: Theme.of(dialogContext).colorScheme.primary,
            size: 40,
          ),
          title: Text(title),
          content: const Text(
            AppStrings.kitchenClosedQuestion,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        final selectedDate = context.read<EatingProvider>().selectedDate;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEntryScreen(
                              targetDate: selectedDate,
                              preselectedReason: EatingReason.hungry,
                            ),
                          ),
                        );
                      },
                      child: const Text(AppStrings.reasonHungry),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        final selectedDate = context.read<EatingProvider>().selectedDate;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEntryScreen(
                              targetDate: selectedDate,
                              preselectedReason: EatingReason.bored,
                            ),
                          ),
                        );
                      },
                      child: const Text(AppStrings.reasonBored),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        final selectedDate = context.read<EatingProvider>().selectedDate;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEntryScreen(
                              targetDate: selectedDate,
                              preselectedReason: EatingReason.habit,
                            ),
                          ),
                        );
                      },
                      child: const Text(AppStrings.reasonHabit),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(
                    AppStrings.gotIt,
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        );
      },
    );
  }

  void _showEntryDetailsDialog(BuildContext context, EatingLog entry) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    if (entry.isMiss)
                      Chip(
                        avatar: const Icon(Icons.close, size: 16),
                        label: const Text(
                          AppStrings.loggedAsMiss,
                          style: TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.restaurant, size: 16),
                            label: Text(
                              '${AppStrings.hunger}: ${entry.hungerLevel}/5',
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          ReasonChip(reason: entry.reason, compact: true),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Logged at ${DateFormat.jm().format(entry.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        if (!entry.isMiss)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text(AppStrings.edit),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            final selectedDate = context.read<EatingProvider>().selectedDate;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEntryScreen(
                                  targetDate: selectedDate,
                                  entryToEdit: entry,
                                ),
                              ),
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          label: const Text(AppStrings.delete, style: TextStyle(color: Colors.redAccent)),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            context.read<EatingProvider>().deleteEatingLog(entry.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppStrings.entryDeleted)),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: AppStrings.weeklyInsights,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MealAnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.preferences,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PreferencesScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<EatingProvider>(
        builder: (context, eatingProvider, child) {
          final selectedDate = eatingProvider.selectedDate;
          final today = DateTime.now();
          final isToday = selectedDate.year == today.year &&
              selectedDate.month == today.month &&
              selectedDate.day == today.day;

          return Column(
            children: [
              _buildOrderBanner(context),
              _buildMissStats(context, eatingProvider),
              // Date navigation
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      onPressed: () {
                        final prevDate = selectedDate.subtract(const Duration(days: 1));
                        context.read<EatingProvider>().setSelectedDate(prevDate);
                      },
                      tooltip: 'Previous day',
                    ),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: eatingProvider.selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null && mounted) {
                          await context.read<EatingProvider>().setSelectedDate(pickedDate);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat.yMMMd().format(selectedDate),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: isToday
                          ? null
                          : () {
                              final nextDate = selectedDate.add(const Duration(days: 1));
                              if (nextDate.isBefore(today) ||
                                  (nextDate.year == today.year &&
                                      nextDate.month == today.month &&
                                      nextDate.day == today.day)) {
                                context.read<EatingProvider>().setSelectedDate(nextDate);
                              }
                            },
                      tooltip: isToday ? 'Cannot go beyond today' : 'Next day',
                    ),
                  ],
                ),
              ),
              // Entry list
              Expanded(
                child: _buildEatingLogsList(eatingProvider.eatingLogs),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'miss',
            onPressed: _logMiss,
            tooltip: AppStrings.logMiss,
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            child: const Icon(Icons.close),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _startAddFlow,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  /// Full-width banner under the app bar priming the "Log → Eat" order.
  Widget _buildOrderBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.orderTagline,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Two engagement stat boxes at the top of the home page.
  Widget _buildMissStats(BuildContext context, EatingProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatBox(
              context,
              value: '${provider.last7DaysMissCount}',
              label: AppStrings.last7DaysMisses,
              icon: Icons.error_outline,
              color: Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatBox(
              context,
              value: '${provider.daysWithoutMissStreak}',
              label: AppStrings.missFreeStreak,
              icon: Icons.local_fire_department,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEatingLogsList(List<EatingLog> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noEntriesTitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.noEntriesSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            leading: log.isMiss
                ? CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    child: const Icon(Icons.close),
                  )
                : HungerIndicator(level: log.hungerLevel),
            title: Text(
              log.description,
              style: const TextStyle(fontSize: 16),
            ),
            subtitle: log.isMiss
                ? const Text(AppStrings.loggedAsMiss)
                : ReasonLabel(reason: log.reason),
            trailing: Text(
              DateFormat.jm().format(log.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () {
              _showEntryDetailsDialog(context, log);
            },
          ),
        );
      },
    );
  }
}

/// Quick "missed meal" dialog. Owns its own controller so it's disposed safely
/// with the dialog's State (never while the route is still animating out).
class _MissEntryDialog extends StatefulWidget {
  const _MissEntryDialog();

  @override
  State<_MissEntryDialog> createState() => _MissEntryDialogState();
}

class _MissEntryDialogState extends State<_MissEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.missDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: AppStrings.missDialogHint,
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
