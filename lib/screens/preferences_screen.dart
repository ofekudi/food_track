import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/strings.dart';
import '../models/day_mode.dart';
import '../models/meal_slot.dart';
import '../providers/settings_provider.dart';

/// Two settings: how big your day is, and which weekdays start out as event
/// days. The per-slot figures are derived from the first, so there's nothing
/// here that can drift out of sync.
class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  Future<void> _editDailyCalories(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _CaloriePickerDialog(initialValue: settings.dailyCalories),
    );
    if (result != null) await settings.setDailyCalories(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.preferences)),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) => ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: const Text(AppStrings.dailyCalories),
              subtitle: const Text(AppStrings.dailyCaloriesSubtitle),
              trailing: Text(
                '${settings.dailyCalories}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _editDailyCalories(context),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                AppStrings.derivedFromTarget,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            for (final slot in MealSlot.meals)
              ListTile(
                dense: true,
                leading: Icon(slot.icon, size: 20),
                title: Text(slot.displayName),
                trailing: Text(
                  AppStrings.calories(
                    slot.calories(DayMode.normal, settings.dailyCalories)!,
                  ),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                AppStrings.caloriesAreReference,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.celebration_outlined),
              title: Text(AppStrings.eventDays),
              subtitle: Text(AppStrings.eventDaysSubtitle),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _WeekdayPicker(
                selected: settings.eventWeekdays,
                onChanged: settings.setEventWeekday,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaloriePickerDialog extends StatefulWidget {
  final int initialValue;

  const _CaloriePickerDialog({required this.initialValue});

  @override
  State<_CaloriePickerDialog> createState() => _CaloriePickerDialogState();
}

class _CaloriePickerDialogState extends State<_CaloriePickerDialog> {
  late int _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const min = SettingsProvider.minDailyCalories;
    const max = SettingsProvider.maxDailyCalories;

    return AlertDialog(
      title: const Text(AppStrings.dailyCalories),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.calories(_value),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: _value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min) ~/ SettingsProvider.step,
            label: '$_value',
            onChanged: (value) => setState(
              () => _value = (value / SettingsProvider.step).round() *
                  SettingsProvider.step,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}

/// Seven toggles, one per weekday, in the order the week starts locally.
class _WeekdayPicker extends StatelessWidget {
  final Set<int> selected;
  final void Function(int weekday, bool isEvent) onChanged;

  const _WeekdayPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // MaterialLocalizations counts from Sunday = 0; DateTime from Monday = 1.
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final weekdays = List.generate(7, (i) {
      final sundayBased = (firstDay + i) % 7;
      return sundayBased == 0 ? DateTime.sunday : sundayBased;
    });
    // Any date with the right weekday will do for a label.
    final monday = DateTime(2024, 1, 1);

    return Row(
      children: [
        for (final weekday in weekdays)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FilterChip(
                showCheckmark: false,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    DateFormat('EEE').format(
                      monday.add(Duration(days: weekday - DateTime.monday)),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                selected: selected.contains(weekday),
                onSelected: (value) => onChanged(weekday, value),
              ),
            ),
          ),
      ],
    );
  }
}
