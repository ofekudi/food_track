import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/day_mode.dart';
import '../models/day_summary.dart';

/// The last seven days, one column each. Every block is one eating occasion:
/// meals at the bottom, extras stacked on top in red.
///
/// Columns are variable height on purpose — a day you grazed through is
/// literally a taller column, so the shape of the week is visible before you
/// read anything.
class WeekStrip extends StatelessWidget {
  final List<DaySummary> week;

  const WeekStrip({super.key, required this.week});

  static const double _areaHeight = 74;
  static const double _blockGap = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final maxBlocks = week.fold<int>(
      4,
      (max, day) => math.max(max, day.filledSlots.length + day.extrasCount),
    );
    final blockHeight =
        ((_areaHeight - (maxBlocks - 1) * _blockGap) / maxBlocks).clamp(3.0, 11.0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in week)
                Expanded(
                  child: _DayColumn(
                    day: day,
                    blockHeight: blockHeight,
                    areaHeight: _areaHeight,
                    blockGap: _blockGap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final DaySummary day;
  final double blockHeight;
  final double areaHeight;
  final double blockGap;

  const _DayColumn({
    required this.day,
    required this.blockHeight,
    required this.areaHeight,
    required this.blockGap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = DateUtils.isSameDay(day.date, DateTime.now());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: areaHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var i = 0; i < day.extrasCount; i++)
                _block(theme.colorScheme.error),
              for (var i = 0; i < day.filledSlots.length; i++)
                _block(theme.colorScheme.primary),
              if (!day.hasAnything)
                _block(theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          DateFormat('EEE').format(day.date)[0],
          style: theme.textTheme.labelSmall?.copyWith(
            color: isToday
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        SizedBox(
          height: 12,
          child: day.mode == DayMode.event
              ? Icon(Icons.celebration_outlined,
                  size: 11, color: theme.colorScheme.tertiary)
              : null,
        ),
      ],
    );
  }

  Widget _block(Color color) => Padding(
        padding: EdgeInsets.only(bottom: blockGap),
        child: Container(
          height: blockHeight,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}
