import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/insights.dart';
import '../constants/strings.dart';
import '../models/day_mode.dart';
import '../models/entry.dart';
import '../models/meal_slot.dart';
import 'plate.dart';
import 'portion_guide_dialog.dart';

/// One of the four meals. Filled or empty, it always holds its place — an
/// empty dinner card at the end of the day is information.
///
/// Two targets, and only two: the round button adds to the slot, and the rest
/// of the card explains what the slot's portions mean. Nothing logs by
/// accident.
class SlotCard extends StatelessWidget {
  final MealSlot slot;
  final DayMode mode;
  final int dailyCalories;
  final List<Entry> entries;
  final VoidCallback onAdd;
  final void Function(Entry entry) onEditEntry;
  final void Function(Entry entry) onDeleteEntry;

  const SlotCard({
    super.key,
    required this.slot,
    required this.mode,
    required this.dailyCalories,
    required this.entries,
    required this.onAdd,
    required this.onEditEntry,
    required this.onDeleteEntry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plate = slot.plate(mode);
    final insight = AppInsights.forSlot(slot, mode);
    final isFilled = entries.isNotEmpty;
    final calories = slot.calories(mode, dailyCalories);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => showSlotPortions(context, slot, mode),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Plate(segments: plate),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      slot.displayName,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        color: isFilled
                                            ? theme.colorScheme.onSurface
                                            : theme
                                                .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (calories != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        AppStrings.calories(calories),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                PlateLegend(segments: plate),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _AddButton(onTap: onAdd),
              ],
            ),
            if (isFilled) ...[
              const SizedBox(height: 6),
              for (final entry in entries)
                _EntryLine(
                  entry: entry,
                  onEdit: () => onEditEntry(entry),
                  onDelete: () => onDeleteEntry(entry),
                ),
            ],
            if (insight != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 8),
                child: Text(
                  insight,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The only way to log into a slot: a filled circle, about as tall as the row.
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: AppStrings.addToSlot,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.add, size: 30, color: scheme.onPrimary),
          ),
        ),
      ),
    );
  }
}

/// One logged item inside a slot, with its own edit and delete.
class _EntryLine extends StatelessWidget {
  final Entry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EntryLine({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(entry.text, style: theme.textTheme.bodyMedium),
            ),
          ),
          Text(
            DateFormat.jm().format(entry.createdAt),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            tooltip: AppStrings.edit,
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            tooltip: AppStrings.delete,
            color: theme.colorScheme.outline,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
