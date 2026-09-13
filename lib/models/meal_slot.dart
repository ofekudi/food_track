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

  /// What one portion of this is worth. At 125 a portion, the plan's own
  /// portion counts reproduce its stated per-meal calories to within 5 — so
  /// these are its numbers, not an invention.
  int get caloriesPerPortion {
    switch (this) {
      case PlateKind.protein:
      case PlateKind.carb:
        return 125;
      case PlateKind.fat:
        return 100;
      case PlateKind.treat:
        return 150;
      case PlateKind.veg:
        // The plan doesn't spend the budget on vegetables — it sets the daily
        // amount separately and treats them as free.
        return 0;
    }
  }

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

  /// What a normal day comes to, as the plan writes it. Slot figures scale
  /// from here, so changing your daily target keeps the proportions intact.
  static const int planDailyCalories = 1960;

  /// The figure the plan states for this meal. These are its numbers verbatim
  /// rather than arithmetic on its portions — the two agree to within 25, and
  /// a test holds them to that, but the written figure is the one to show.
  int? _statedCalories(DayMode mode) {
    if (mode == DayMode.event) {
      switch (this) {
        case MealSlot.breakfast:
          return 370; // the weekday breakfast without its fat portion
        case MealSlot.lunch:
          return 470;
        case MealSlot.snack:
          return 150; // the yogurt, without the treat
        case MealSlot.dinner:
          // The plan gives no figure for a restaurant meal — it says to bank
          // room by combining the earlier slots. This is what that buys.
          return 1000;
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

  /// What this meal's own portions come to, at the plan's per-portion rates.
  /// Used to check the stated figures, and as the fallback if one is missing.
  int portionCalories(DayMode mode) => plate(mode).fold<int>(
        0,
        (sum, segment) =>
            sum + segment.portions * segment.kind.caloriesPerPortion,
      );

  /// Roughly what this meal comes to, scaled to [dailyTarget]. A reference for
  /// the shape of the day, not a measurement of what you ate.
  int? calories(DayMode mode, int dailyTarget) {
    if (isExtra) return null;
    final base = _statedCalories(mode) ?? portionCalories(mode);
    final scaled = base * dailyTarget / planDailyCalories;
    return (scaled / 10).round() * 10; // tidy, since it's only a reference
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
          // The plan puts this at 370 — the weekday breakfast without its fat
          // portion, which is exactly 470 minus 100.
          return const [
            PlateSegment(PlateKind.protein, 2),
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
          // The plan gives no figure for a restaurant meal — it says to bank
          // room by combining the earlier slots, and these counts are what
          // that room buys, keeping an event day level with a normal one.
          return const [
            PlateSegment(PlateKind.protein, 4),
            PlateSegment(PlateKind.carb, 4),
            PlateSegment(PlateKind.veg, 4),
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
