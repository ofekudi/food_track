import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/eating_provider.dart';
import '../providers/settings_provider.dart';
import '../models/eating_log.dart';
import '../constants/strings.dart';
import '../widgets/hunger_indicator.dart';
import '../widgets/recordings_chart.dart';
import '../widgets/reason_chip.dart';
import 'add_entry_screen.dart';
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

    final eatingProvider = context.read<EatingProvider>();
    final selectedDate = eatingProvider.selectedDate;

    // Only intervene on today — back-filling an older day shouldn't be nagged.
    final target = settingsProvider.recordingsTarget;
    final todayCount = eatingProvider.todayRecordingCount;
    if (_isToday(selectedDate) && todayCount >= target) {
      _showOverTargetDialog(todayCount, target);
      return;
    }

    if (_shouldShowKitchenClosedReminder()) {
      _showKitchenClosedDialog(settingsProvider.stopEatingTitle);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEntryScreen(targetDate: selectedDate),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Opens the add flow for the day being browsed, optionally with the reason
  /// already picked from an intervention dialog.
  void _openAddEntry({EatingReason? preselectedReason}) {
    final selectedDate = context.read<EatingProvider>().selectedDate;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEntryScreen(
          targetDate: selectedDate,
          preselectedReason: preselectedReason,
        ),
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
    _showInterventionDialog(
      icon: Icons.bedtime_outlined,
      title: title,
      body: AppStrings.kitchenClosedQuestion,
    );
  }

  /// Shown when today has already hit the recordings target — the yell lands
  /// here, before the add flow, rather than in a chart you have to interpret.
  void _showOverTargetDialog(int count, int target) {
    _showInterventionDialog(
      icon: Icons.flag_outlined,
      title: AppStrings.overTargetTitle,
      body: AppStrings.overTargetBody(count, target),
    );
  }

  /// Pre-log check-in: a reason shortcut for every reason (each continues into
  /// the add flow with it preselected) plus a plain dismiss.
  void _showInterventionDialog({
    required IconData icon,
    required String title,
    required String body,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            icon,
            color: Theme.of(dialogContext).colorScheme.primary,
            size: 40,
          ),
          title: Text(title, textAlign: TextAlign.center),
          content: Text(body, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: [
                    for (final reason in EatingReason.values)
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _openAddEntry(preselectedReason: reason);
                        },
                        child: Text(reason.displayName),
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
              _buildTrends(context, eatingProvider),
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

  /// The single 7-day card at the top of the page: recordings per day stacked
  /// into logged vs. missed, against the daily target.
  Widget _buildTrends(BuildContext context, EatingProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) =>
            _buildRecordingsCard(context, provider, settings.recordingsTarget),
      ),
    );
  }

  Widget _buildRecordingsCard(
    BuildContext context,
    EatingProvider provider,
    int target,
  ) {
    final theme = Theme.of(context);
    final streak = provider.daysOnTargetStreak(target);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The card's only copy. Everything else the chart says for itself:
          // the bars, the dashed target line with its value, the weekday
          // letters, and red for the blocks that were misses.
          Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _trendHeaderLabel(
                context,
                '$streak${AppStrings.onTargetStreakSuffix}',
                icon: Icons.local_fire_department,
                color: streak > 0 ? Colors.green : null,
              ),
              _trendHeaderSeparator(context),
              _trendHeaderLabel(
                context,
                AppStrings.missesInWeek(provider.last7DaysMissCount),
                icon: Icons.error_outline,
                color: provider.last7DaysMissCount > 0 ? Colors.red : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          RecordingsChart(
            totals: provider.last7DaysRecordingCountsByDay,
            misses: provider.last7DaysMissCountsByDay,
            target: target,
            loggedColor: Colors.green,
            missColor: Colors.red,
          ),
        ],
      ),
    );
  }

  /// One piece of a trend card's title, optionally prefixed with a small icon.
  Widget _trendHeaderLabel(
    BuildContext context,
    String text, {
    IconData? icon,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: color ?? theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final label = Text(text, style: style);
    if (icon == null) return label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        label,
      ],
    );
  }

  Widget _trendHeaderSeparator(BuildContext context) => Text(
        '·',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      );

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
