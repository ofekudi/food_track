import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../models/meal_slot.dart';

/// A small ring showing what a meal should roughly look like — half protein,
/// a quarter carb, and so on. It's a reference picture, never an input: there
/// is nothing here to fill in, weigh or count.
///
/// On an event dinner this is the plan's "Mercedes plate" — thirds of protein,
/// carb and veg — which is why the same widget draws every slot rather than
/// that one being a special case.
class Plate extends StatelessWidget {
  final List<PlateSegment> segments;
  final double size;

  const Plate({super.key, required this.segments, this.size = 38});

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return SizedBox(width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PlatePainter(segments: segments)),
    );
  }
}

class _PlatePainter extends CustomPainter {
  final List<PlateSegment> segments;

  _PlatePainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.34;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - stroke) / 2,
    );

    // A hair of padding between wedges so they read as separate at small sizes.
    const gap = 0.05;
    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = segments.fractionOf(segment) * 2 * math.pi;
      final paint = Paint()
        ..color = AppTheme.plateColor(segment.kind)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start + gap / 2, sweep - gap, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_PlatePainter old) => old.segments != segments;
}

/// The plate's key in the plan's own units: "2 protein · 1 carb · 1 fat".
///
/// Portions rather than percentages on purpose — it's what the plan is written
/// in, and what you learn to eyeball with practice. A percentage would have to
/// be translated every time.
class PlateLegend extends StatelessWidget {
  final List<PlateSegment> segments;

  const PlateLegend({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Text(
      segments
          .map((s) => '${s.portions} ${s.kind.displayName.toLowerCase()}')
          .join(' · '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
