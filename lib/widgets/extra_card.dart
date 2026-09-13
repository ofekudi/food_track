import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/insights.dart';
import '../constants/strings.dart';
import '../models/entry.dart';

/// One thing eaten outside the slots, on its own row.
///
/// It gets the same footprint as a meal card on purpose: three extras should
/// make the day look three rows longer. That's the whole intervention — the
/// layout says it, so no dialog has to.
class ExtraCard extends StatelessWidget {
  final Entry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Whether to carry the "no offsetting" rule. Set on the day's last extra
  /// only — it's the one still worth reading, and repeating it on every row
  /// would turn a useful rule into nagging.
  final bool showRule;

  const ExtraCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    this.showRule = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.error;

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 34,
              alignment: Alignment.center,
              child: Icon(Icons.remove_circle_outline,
                  size: 20, color: accent.withValues(alpha: 0.8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppStrings.slotExtra,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.jm().format(entry.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(entry.text, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
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
      ),
    );

    if (!showRule) return card;

    return Column(
      children: [
        card,
        Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 26, 8),
          child: Text(
            AppInsights.noOffsetting,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
