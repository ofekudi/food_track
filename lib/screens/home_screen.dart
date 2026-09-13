import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/insights.dart';
import '../constants/strings.dart';
import '../models/day_mode.dart';
import '../models/day_timeline.dart';
import '../models/entry.dart';
import '../models/meal_slot.dart';
import '../providers/day_provider.dart';
import '../providers/settings_provider.dart';
import 'preferences_screen.dart';
import '../widgets/extra_card.dart';
import '../widgets/log_dialog.dart';
import '../widgets/slot_card.dart';
import '../widgets/top_notice.dart';
import '../widgets/week_strip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _log(BuildContext context, MealSlot slot) async {
    final provider = context.read<DayProvider>();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => LogDialog(slot: slot),
    );
    if (text == null) return;

    await provider.addEntry(slot: slot, text: text);
  }

  Future<void> _edit(BuildContext context, Entry entry) async {
    final provider = context.read<DayProvider>();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => LogDialog(slot: entry.slot, initialText: entry.text),
    );
    if (text == null) return;
    await provider.updateEntryText(entry.id, text);
  }

  Future<void> _delete(BuildContext context, Entry entry) async {
    await context.read<DayProvider>().deleteEntry(entry.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.entryDeleted)),
    );
  }

  Future<void> _toggleMode(BuildContext context) async {
    final provider = context.read<DayProvider>();
    final next =
        provider.mode == DayMode.event ? DayMode.normal : DayMode.event;
    await provider.setMode(next);
    if (next == DayMode.event && context.mounted) {
      showTopNotice(context, AppInsights.eventDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(AppStrings.appName),
        actions: [
          Consumer<DayProvider>(
            builder: (context, provider, _) {
              final isEvent = provider.mode == DayMode.event;
              return IconButton(
                icon: Icon(isEvent
                    ? Icons.celebration
                    : Icons.celebration_outlined),
                color: isEvent ? Theme.of(context).colorScheme.tertiary : null,
                tooltip: AppStrings.eventModeTooltip,
                onPressed: () => _toggleMode(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: AppStrings.preferences,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PreferencesScreen()),
            ),
          ),
        ],
      ),
      body: Consumer2<DayProvider, SettingsProvider>(
        builder: (context, provider, settings, _) {
          return Column(
            children: [
              WeekStrip(week: provider.week),
              _DateNav(provider: provider),
              Expanded(
                child: _buildTimeline(
                    context, provider, settings.dailyCalories),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeline(
      BuildContext context, DayProvider provider, int dailyCalories) {
    final items = provider.timeline;
    final lastExtraId = items.whereType<ExtraItem>().lastOrNull?.entry.id;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: OutlinedButton.icon(
              onPressed: () => _log(context, MealSlot.extras),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(AppStrings.addExtra),
            ),
          );
        }

        final item = items[index];
        return switch (item) {
          SlotItem() => SlotCard(
              slot: item.slot,
              mode: provider.mode,
              dailyCalories: dailyCalories,
              entries: item.entries,
              onAdd: () => _log(context, item.slot),
              onEditEntry: (entry) => _edit(context, entry),
              onDeleteEntry: (entry) => _delete(context, entry),
            ),
          ExtraItem() => ExtraCard(
              entry: item.entry,
              showRule: item.entry.id == lastExtraId,
              onEdit: () => _edit(context, item.entry),
              onDelete: () => _delete(context, item.entry),
            ),
        };
      },
    );
  }
}

class _DateNav extends StatelessWidget {
  final DayProvider provider;

  const _DateNav({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = provider.selectedDate;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 14),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            tooltip: AppStrings.previousDay,
            onPressed: () => provider
                .setSelectedDate(selected.subtract(const Duration(days: 1))),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selected,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) await provider.setSelectedDate(picked);
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.yMMMd().format(selected),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.calendar_today,
                      size: 13, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 14),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            tooltip: provider.isToday
                ? AppStrings.cannotGoBeyondToday
                : AppStrings.nextDay,
            onPressed: provider.isToday
                ? null
                : () => provider
                    .setSelectedDate(selected.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }
}
