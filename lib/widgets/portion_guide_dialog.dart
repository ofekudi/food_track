import 'package:flutter/material.dart';
import '../constants/portion_guide.dart';
import '../constants/strings.dart';
import '../constants/theme.dart';
import '../models/day_mode.dart';
import '../models/meal_slot.dart';

/// What this meal's portions actually mean. Tapping breakfast's plate answers
/// "what is 2 protein?" in place, rather than sending you to a reference table
/// to do the lookup yourself.
void showSlotPortions(BuildContext context, MealSlot slot, DayMode mode) {
  final plate = slot.plate(mode);
  if (plate.isEmpty) return;
  showDialog(
    context: context,
    builder: (_) => _PortionDialog(
      title: slot.displayName,
      rows: [
        for (final segment in plate)
          _PortionRow(kind: segment.kind, count: segment.portions),
      ],
    ),
  );
}

class _PortionDialog extends StatelessWidget {
  final String title;
  final List<_PortionRow> rows;

  const _PortionDialog({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      content: SizedBox(
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.done),
        ),
      ],
    );
  }
}

/// One line: "2 protein — a palm of chicken, 3 tbsp cottage, 2 eggs".
class _PortionRow extends StatelessWidget {
  final PlateKind kind;
  final int? count;

  const _PortionRow({required this.kind, this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count == null
        ? kind.displayName
        : '$count ${kind.displayName.toLowerCase()}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.plateColor(kind),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: label,
                    style: theme.textTheme.titleSmall,
                    children: [
                      TextSpan(
                        text: '  ${PortionGuide.worth(kind, count ?? 1)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  PortionGuide.examples(kind)
                      .map((example) => example.scaled(count ?? 1))
                      .join(', '),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
