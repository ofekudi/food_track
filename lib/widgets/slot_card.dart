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
/// Once a slot has something in it the whole card folds down to just its
/// name and a chevron. The portion legend and the reminder were there to help
/// you decide, and the deciding is done — so the slots still open are the
/// loudest thing on screen. Tap to unfold and see, edit or delete what's
/// there; the round button still adds.
///
/// Nothing logs by accident: the round button is the only thing that opens
/// the log dialog.
class SlotCard extends StatefulWidget {
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
  State<SlotCard> createState() => _SlotCardState();
}

class _SlotCardState extends State<SlotCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final mode = widget.mode;
    final entries = widget.entries;

    final theme = Theme.of(context);
    final plate = slot.plate(mode);
    final insight = AppInsights.forSlot(slot, mode);
    final isFilled = entries.isNotEmpty;
    final calories = slot.calories(mode, widget.dailyCalories);
    final showDetail = !isFilled || _expanded;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: isFilled ? 2 : 5),
      elevation: isFilled ? 0 : null,
      color: isFilled
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
          : null,
      child: Opacity(
        // Dims the whole row, not just the plate: a slot you've dealt with
        // should recede as one thing, so the open ones carry the screen.
        opacity: isFilled ? 0.35 : 1,
        child: Padding(
          padding:
              EdgeInsets.fromLTRB(14, isFilled ? 2 : 12, 12, isFilled ? 2 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      // Once it's filled the card folds, so tapping it
                      // unfolds; while it's empty the portions are what you
                      // want to see.
                      onTap: isFilled
                          ? () => setState(() => _expanded = !_expanded)
                          : () => showSlotPortions(context, slot, mode),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: isFilled ? 0 : 4),
                        child: Row(
                          children: [
                            Plate(segments: plate, size: isFilled ? 22 : 38),
                            SizedBox(width: isFilled ? 10 : 12),
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
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          color: isFilled
                                              ? theme.colorScheme.onSurface
                                              : theme
                                                  .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      if (isFilled) ...[
                                        const SizedBox(width: 2),
                                        Icon(
                                          _expanded
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          size: 18,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ] else if (calories != null) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          AppStrings.calories(calories),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (!isFilled) ...[
                                    const SizedBox(height: 2),
                                    PlateLegend(segments: plate),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _AddButton(onTap: widget.onAdd, size: isFilled ? 32 : 52),
                ],
              ),
              if (isFilled && _expanded) ...[
                const SizedBox(height: 6),
                for (final entry in entries)
                  _EntryLine(
                    entry: entry,
                    onEdit: () => widget.onEditEntry(entry),
                    onDelete: () => widget.onDeleteEntry(entry),
                  ),
              ],
              if (insight != null && showDetail && !isFilled) ...[
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
      ),
    );
  }
}

/// The only way to log into a slot: a filled circle, about as tall as the row.
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  /// Shrinks with the rest of the row once the slot is dealt with.
  final double size;

  const _AddButton({required this.onTap, this.size = 52});

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
            width: size,
            height: size,
            child: Icon(Icons.add, size: size * 0.58, color: scheme.onPrimary),
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
