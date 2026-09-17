import 'package:flutter/material.dart';
import '../models/meal_slot.dart';

/// App-wide theme constants.
class AppTheme {
  /// Colour for one wedge of a composition plate. Deliberately saturated and
  /// distinct rather than shades of the seed colour — the plate has to read at
  /// 36px.
  static Color plateColor(PlateKind kind) {
    switch (kind) {
      case PlateKind.protein:
        return const Color(0xFFFF3D00);
      case PlateKind.carb:
        return const Color(0xFFFFC400);
      case PlateKind.fat:
        return const Color(0xFF2979FF);
      case PlateKind.veg:
        return const Color(0xFF00E676);
      case PlateKind.treat:
        return const Color(0xFFD500F9);
    }
  }
}
