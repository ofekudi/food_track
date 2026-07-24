import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Stacked bar chart of recordings per day (oldest → today) against a daily
/// target.
///
/// Every recording is one block, stacked bottom-up, and each block is colored
/// by what's wrong with it — worst first:
/// * **[missColor]** — it was a miss (eaten first, logged after).
/// * **[overTargetColor]** — it sits above the [target] line.
/// * **[withinTargetColor]** — a clean, planned recording.
///
/// Misses stack at the bottom, so a day of 4 with 3 misses reads as three red
/// blocks with a single over-target block on top.
class RecordingsChart extends StatelessWidget {
  /// Total recordings per day, oldest → today. The last entry is today.
  final List<int> totals;

  /// Misses per day, oldest → today. A subset of [totals].
  final List<int> misses;

  /// The daily target the dashed line sits at.
  final int target;

  /// Color of the count printed above each bar, resolved from that day's total.
  final Color Function(int total) countColor;

  final Color withinTargetColor;
  final Color overTargetColor;
  final Color missColor;

  final double height;

  const RecordingsChart({
    super.key,
    required this.totals,
    required this.misses,
    required this.target,
    required this.countColor,
    required this.withinTargetColor,
    required this.overTargetColor,
    required this.missColor,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayLabels = List.generate(totals.length, (i) {
      final day = today.subtract(Duration(days: totals.length - 1 - i));
      return DateFormat('EEE').format(day)[0];
    });

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _RecordingsPainter(
          totals: totals,
          misses: misses,
          target: target,
          dayLabels: dayLabels,
          countColor: countColor,
          withinTargetColor: withinTargetColor,
          overTargetColor: overTargetColor,
          missColor: missColor,
          targetLineColor: theme.colorScheme.onSurfaceVariant,
          mutedColor: theme.colorScheme.outlineVariant,
          todayColor: theme.colorScheme.primary,
          countStyle: theme.textTheme.labelMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ) ??
              const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          labelStyle: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ) ??
              const TextStyle(fontSize: 11),
          todayLabelStyle: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ) ??
              TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}

class _RecordingsPainter extends CustomPainter {
  final List<int> totals;
  final List<int> misses;
  final int target;
  final List<String> dayLabels;
  final Color Function(int total) countColor;
  final Color withinTargetColor;
  final Color overTargetColor;
  final Color missColor;
  final Color targetLineColor;
  final Color mutedColor;
  final Color todayColor;
  final TextStyle countStyle;
  final TextStyle labelStyle;
  final TextStyle todayLabelStyle;

  _RecordingsPainter({
    required this.totals,
    required this.misses,
    required this.target,
    required this.dayLabels,
    required this.countColor,
    required this.withinTargetColor,
    required this.overTargetColor,
    required this.missColor,
    required this.targetLineColor,
    required this.mutedColor,
    required this.todayColor,
    required this.countStyle,
    required this.labelStyle,
    required this.todayLabelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totals.isEmpty) return;

    const double topReserve = 24; // room for the count above each bar
    const double bottomReserve = 18; // room for the weekday label
    const double sideInset = 14; // left gutter also holds the target's value
    final double plotTop = topReserve;
    final double plotBottom = size.height - bottomReserve;
    final int n = totals.length;
    final double slot = (size.width - 2 * sideInset) / n;
    final double barWidth = math.min(22, slot * 0.6);
    final int maxTotal = totals.fold<int>(0, (m, v) => v > m ? v : m);
    // Keep the target line inside the plot even on a quiet week.
    final int yMax = math.max(maxTotal, target + 1);
    final int todayIndex = n - 1;

    double centerX(int i) => sideInset + slot * (i + 0.5);
    double yForValue(num value) =>
        plotBottom - (value / yMax) * (plotBottom - plotTop);

    // Baseline the bars sit on.
    canvas.drawLine(
      Offset(sideInset, plotBottom),
      Offset(size.width - sideInset, plotBottom),
      Paint()
        ..color = mutedColor
        ..strokeWidth = 1,
    );

    for (int i = 0; i < n; i++) {
      final int total = totals[i];
      final int missed = math.min(total, misses.length > i ? misses[i] : 0);
      final double left = centerX(i) - barWidth / 2;
      final bool isToday = i == todayIndex;

      // Today's slot gets a faint tint so "where am I now" is obvious without
      // competing with the count label above the bar.
      if (isToday) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(left - 5, plotTop - 4, left + barWidth + 5, plotBottom),
            const Radius.circular(4),
          ),
          Paint()..color = todayColor.withValues(alpha: 0.08),
        );
      }

      // One block per recording, stacked bottom-up. Misses sit at the bottom
      // so the blocks that break the target line are the surplus ones.
      for (int unit = 0; unit < total; unit++) {
        final Color color = unit < missed
            ? missColor
            : (unit >= target ? overTargetColor : withinTargetColor);
        _paintBlock(canvas, left, barWidth, unit, yForValue, color);
      }

      // Count above the bar (or above the baseline on an empty day).
      final double labelY =
          total > 0 ? yForValue(total) - 4 : plotBottom - 4;
      _paintText(
        canvas,
        '$total',
        countStyle.copyWith(color: countColor(total)),
        centerX(i),
        labelY,
        center: true,
        anchorBottom: true,
      );

      // Weekday letter at the bottom.
      _paintText(
        canvas,
        dayLabels[i],
        isToday ? todayLabelStyle : labelStyle,
        centerX(i),
        size.height - bottomReserve + 2,
        center: true,
      );
    }

    // Dashed target line last, so it reads across the bars it cuts through.
    final double targetY = yForValue(target);
    final dashPaint = Paint()
      ..color = targetLineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    const double dash = 9, gap = 5;
    final double lineEnd = size.width - sideInset;
    for (double x = sideInset; x < lineEnd; x += dash + gap) {
      canvas.drawLine(
        Offset(x, targetY),
        Offset(math.min(x + dash, lineEnd), targetY),
        dashPaint,
      );
    }

    // The target value, sitting on the line at the left edge so the dashes
    // read as a threshold rather than decoration.
    _paintText(
      canvas,
      '$target',
      countStyle.copyWith(color: targetLineColor, fontSize: 11),
      0,
      targetY - 3,
      anchorBottom: true,
    );
  }

  /// Paints the [unit]-th block of a bar (0 = bottom) as a discrete tile, so a
  /// day's recordings can be counted and color-read one by one.
  void _paintBlock(
    Canvas canvas,
    double left,
    double width,
    int unit,
    double Function(num) yForValue,
    Color color,
  ) {
    final double top = yForValue(unit + 1);
    final double bottom = yForValue(unit);
    // Hairline gap between blocks, dropped once they get too thin to afford it.
    final double bandHeight = bottom - top;
    final double gap = bandHeight > 6 ? 1.5 : 0;
    final double radius = bandHeight > 6 ? 2 : 0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, left + width, bottom - gap),
        Radius.circular(radius),
      ),
      Paint()..color = color,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    TextStyle style,
    double centerX,
    double y, {
    bool center = false,
    bool anchorBottom = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final dx = centerX - (center ? tp.width / 2 : 0);
    final dy = anchorBottom ? y - tp.height : y;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_RecordingsPainter oldDelegate) =>
      oldDelegate.totals != totals ||
      oldDelegate.misses != misses ||
      oldDelegate.target != target ||
      oldDelegate.countColor != countColor ||
      oldDelegate.withinTargetColor != withinTargetColor ||
      oldDelegate.overTargetColor != overTargetColor ||
      oldDelegate.missColor != missColor ||
      oldDelegate.todayColor != todayColor;
}
