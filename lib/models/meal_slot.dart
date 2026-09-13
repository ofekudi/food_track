import 'package:flutter/material.dart';
import '../constants/strings.dart';
import 'day_mode.dart';

/// What one wedge of a slot's composition plate stands for. These are never
/// counted or weighed — the plate is a picture of what the meal should look
/// like, not a budget to fill in.
enum PlateKind {
  protein,
  carb,
  fat,
  veg,
  treat;

  String get displayName {
    switch (this) {
      case PlateKind.protein:
        return AppStrings.plateProtein;
      case PlateKind.carb:
        return AppStrings.plateCarb;
      case PlateKind.fat:
        return AppStrings.plateFat;
      case PlateKind.veg:
        return AppStrings.plateVeg;
      case PlateKind.treat:
        return AppStrings.plateTreat;
    }
  }
}

/// One wedge of a plate: what it is, and how many portions of it the meal
/// holds — the plan's own unit (מנות), so the label reads "2 protein · 1 carb
/// · 1 fat" rather than a percentage you'd have to translate.
///
/// The ring is drawn from the ratio between these, so portions and picture can
/// never disagree.
class PlateSegment {
  final PlateKind kind;
  final int portions;

  const PlateSegment(this.kind, this.portions);
}

extension PlateSegments on List<PlateSegment> {
  int get totalPortions => fold(0, (sum, segment) => sum + segment.portions);

  /// This wedge's share of the ring.
  double fractionOf(PlateSegment segment) =>
      totalPortions == 0 ? 0 : segment.portions / totalPortions;
}

/// The fixed places food can go in a day. Four meals, plus [extras] for
/// anything eaten outside them.
enum MealSlot {
  breakfast,
  lunch,
  snack,
  dinner,
  extras;

  bool get isExtra => this == MealSlot.extras;

  String get displayName {
    switch (this) {
      case MealSlot.breakfast:
        return AppStrings.slotBreakfast;
      case MealSlot.lunch:
        return AppStrings.slotLunch;
      case MealSlot.snack:
        return AppStrings.slotSnack;
      case MealSlot.dinner:
        return AppStrings.slotDinner;
      case MealSlot.extras:
        return AppStrings.slotExtra;
    }
  }

  IconData get icon {
    switch (this) {
      case MealSlot.breakfast:
        return Icons.wb_twilight;
      case MealSlot.lunch:
        return Icons.light_mode_outlined;
      case MealSlot.snack:
        return Icons.icecream_outlined;
      case MealSlot.dinner:
        return Icons.nightlight_outlined;
      case MealSlot.extras:
        return Icons.add_circle_outline;
    }
  }

  /// Where an unfilled slot sits when the day is laid out in order. Anything
  /// actually logged sorts by its own timestamp instead, so these are only
  /// placeholders for meals that haven't happened yet.
  int get defaultMinutes {
    switch (this) {
      case MealSlot.breakfast:
        return 8 * 60;
      case MealSlot.lunch:
        return 13 * 60;
      case MealSlot.snack:
        return 16 * 60 + 30;
      case MealSlot.dinner:
        return 20 * 60;
      case MealSlot.extras:
        return 0;
    }
  }

  /// What the plan's own per-meal figures add up to. Slot figures are stored
  /// as written and scaled from here, so changing your daily target keeps the
  /// plan's proportions intact.
  static const int planDailyCalories = 1960;

  /// Roughly what this meal is meant to come to, scaled to [dailyTarget].
  /// A reference for the shape of the day, not a measurement of what you ate
  /// — nothing here is counted or estimated.
  int? calories(DayMode mode, int dailyTarget) {
    final base = _planCalories(mode);
    if (base == null) return null;
    final scaled = base * dailyTarget / planDailyCalories;
    return (scaled / 10).round() * 10; // tidy, since it's only a reference
  }

  /// The plan's figure for this meal, as written.
  int? _planCalories(DayMode mode) {
    if (mode == DayMode.event) {
      switch (this) {
        case MealSlot.breakfast:
          return 370;
        case MealSlot.lunch:
          return 470;
        case MealSlot.snack:
          return 150; // yogurt only, no treat
        case MealSlot.dinner:
          return null; // a restaurant meal; the plan gives no figure
        case MealSlot.extras:
          return null;
      }
    }
    switch (this) {
      case MealSlot.breakfast:
      case MealSlot.dinner:
        return 470;
      case MealSlot.lunch:
        return 720;
      case MealSlot.snack:
        return 300; // yogurt plus the ~150 treat
      case MealSlot.extras:
        return null;
    }
  }

  /// The four real meals, in the order they happen.
  static List<MealSlot> get meals => const [
        MealSlot.breakfast,
        MealSlot.lunch,
        MealSlot.snack,
        MealSlot.dinner,
      ];

  /// The slot you're most likely logging at [time]. Only a guess to save a tap
  /// — the log sheet always lets you pick a different one.
  static MealSlot forTime(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    if (minutes < 11 * 60) return MealSlot.breakfast;
    if (minutes < 15 * 60 + 30) return MealSlot.lunch;
    if (minutes < 18 * 60 + 30) return MealSlot.snack;
    return MealSlot.dinner;
  }

  /// What this meal is made of, in the plan's portions. Extras have no
  /// intended shape — they're whatever happened.
  List<PlateSegment> plate(DayMode mode) {
    if (isExtra) return const [];

    if (mode == DayMode.event) {
      switch (this) {
        case MealSlot.breakfast:
          return const [
            PlateSegment(PlateKind.protein, 1),
            PlateSegment(PlateKind.carb, 1),
          ];
        case MealSlot.lunch:
          return const [
            PlateSegment(PlateKind.protein, 2),
            PlateSegment(PlateKind.carb, 1),
            PlateSegment(PlateKind.fat, 1),
          ];
        case MealSlot.snack:
          return const [PlateSegment(PlateKind.protein, 1)];
        case MealSlot.dinner:
          // The Mercedes plate: equal parts, and the looser meal of the day.
          return const [
            PlateSegment(PlateKind.protein, 1),
            PlateSegment(PlateKind.carb, 1),
            PlateSegment(PlateKind.veg, 1),
          ];
        case MealSlot.extras:
          return const [];
      }
    }

    switch (this) {
      case MealSlot.breakfast:
      case MealSlot.dinner:
        return const [
          PlateSegment(PlateKind.protein, 2),
          PlateSegment(PlateKind.carb, 1),
          PlateSegment(PlateKind.fat, 1),
        ];
      case MealSlot.lunch:
        return const [
          PlateSegment(PlateKind.protein, 3),
          PlateSegment(PlateKind.carb, 2),
          PlateSegment(PlateKind.fat, 1),
        ];
      case MealSlot.snack:
        return const [
          PlateSegment(PlateKind.protein, 1),
          PlateSegment(PlateKind.treat, 1),
        ];
      case MealSlot.extras:
        return const [];
    }
  }

  static MealSlot fromString(String? value) => MealSlot.values.firstWhere(
        (s) => s.name == value,
        orElse: () => MealSlot.extras,
      );
}
