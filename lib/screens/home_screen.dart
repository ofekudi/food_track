import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/eating_provider.dart';
import '../providers/settings_provider.dart';
import '../models/eating_log.dart';
import '../constants/strings.dart';
import '../widgets/hunger_indicator.dart';
import '../widgets/reason_chip.dart';
import '../widgets/suggestion_tile.dart';
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
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _checkKitchenClosed();
      }
    });
  }

  void _checkKitchenClosed() {
    if (!mounted) return;

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    if (!settingsProvider.stopEatingEnabled) return;

    final kitchenClosedTime = settingsProvider.kitchenClosedTime;
    final bannerTitle = settingsProvider.stopEatingTitle;

    if (kitchenClosedTime != null) {
      final now = TimeOfDay.now();
      final nowMinutes = now.hour * 60 + now.minute;
      final closedMinutes = kitchenClosedTime.hour * 60 + kitchenClosedTime.minute;

      if (nowMinutes >= closedMinutes) {
        _showKitchenClosedDialog(bannerTitle);
      }
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
                            builder: (context) => AddEntryScreen(targetDate: selectedDate),
                          ),
                        );
                      },
                      child: const Text(AppStrings.reasonHungry),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _showBoredSuggestions();
                      },
                      child: const Text(AppStrings.reasonBored),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _showBoredSuggestions();
                      },
                      child: const Text(AppStrings.habit),
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

  void _showBoredSuggestions() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(
            Icons.lightbulb_outline,
            color: Theme.of(dialogContext).colorScheme.primary,
            size: 40,
          ),
          title: const Text(AppStrings.tryTheseInstead),
          content: const SuggestionsList(compact: true),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final selectedDate = context.read<EatingProvider>().selectedDate;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MindfulnessTimerScreen(targetDate: selectedDate),
                  ),
                );
              },
              child: const Text(AppStrings.logAnyway),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(AppStrings.gotIt),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Chip(
                        avatar: const Icon(Icons.restaurant, size: 16),
                        label: Text(
                          '${AppStrings.hunger}: ${entry.hungerLevel}/5',
                          style: const TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final selectedDate = context.read<EatingProvider>().selectedDate;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MindfulnessTimerScreen(targetDate: selectedDate),
            ),
          );
        },
        child: const Icon(Icons.add),
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
            leading: HungerIndicator(level: log.hungerLevel),
            title: Text(
              log.description,
              style: const TextStyle(fontSize: 16),
            ),
            subtitle: ReasonLabel(reason: log.reason),
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
