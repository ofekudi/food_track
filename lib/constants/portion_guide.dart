import '../models/meal_slot.dart';

/// One concrete example of a portion, in a form that can be multiplied — so a
/// meal listing "3 protein" shows 225g of chicken rather than the 75g that one
/// portion is, and you never have to do the arithmetic yourself.
class PortionExample {
  final double amount;

  /// 'g', 'tsp', 'tbsp', or empty for countable things ("2 eggs").
  final String unit;
  final String label;

  /// Used once the quantity passes 1, e.g. "palms of chicken".
  final String? plural;

  const PortionExample(this.amount, this.unit, this.label, {this.plural});

  /// This example at [portions] portions, e.g. "2\u00bc palms of chicken".
  String scaled(int portions) {
    final total = amount * portions;
    if (unit == 'g') {
      // Rounded to the nearest 5 — it's an eyeball measure, not a weigh-in.
      final grams = (total / 5).round() * 5;
      return '${grams}g $label';
    }
    // Snapped to a quarter: a palm is an eyeball measure, and "0.8 palms"
    // would be false precision.
    final rounded = (total * 4).round() / 4;
    final name = rounded > 1 ? (plural ?? label) : label;
    final quantity = _format(rounded);
    return unit.isEmpty ? '$quantity $name' : '$quantity $unit $name';
  }

  static const _fractions = <(double, String)>[
    (0.25, '\u00bc'),
    (0.5, '\u00bd'),
    (0.75, '\u00be'),
  ];

  static String _format(double value) {
    final whole = value.floor();
    final fraction = value - whole;
    if (fraction < 0.01) return whole.toString();
    for (final (size, glyph) in _fractions) {
      if ((fraction - size).abs() < 0.01) {
        return whole == 0 ? glyph : '$whole$glyph';
      }
    }
    return value.toStringAsFixed(1);
  }
}

/// What a portion actually is, so the numbers on a slot card mean something
/// without a scale.
///
/// Quantities are the plan's own wherever it states them. Where it only gives
/// a multi-portion figure, the single portion is derived from it — see the
/// notes on each case.
class PortionGuide {
  /// The plan states a protein portion as 10–15g. A snack's protein is a
  /// yogurt or a bar, which run richer.
  static double _proteinGrams(MealSlot? slot) =>
      slot == MealSlot.snack ? 20 : 12.5;

  /// What [portions] of this are worth — a single figure rather than a range,
  /// so there's nothing left to work out before you can use it.
  ///
  /// Protein carries its gram figure too, since that's the number worth
  /// watching on a cut. Treat it as a floor: lean choices run well above it,
  /// which is most of the difference between a 100g day and a 180g one.
  static String worth(PlateKind kind, int portions, {MealSlot? slot}) {
    final cal = _round(kind.caloriesPerPortion * portions);
    switch (kind) {
      case PlateKind.protein:
        return '$cal cal · ${_round(_proteinGrams(slot) * portions)}g protein';
      case PlateKind.veg:
        return '${_round(125 * portions)}g';
      case PlateKind.carb:
      case PlateKind.fat:
      case PlateKind.treat:
        return '$cal cal';
    }
  }

  /// To the nearest 5 — these are reference figures, not measurements.
  static int _round(num value) => (value / 5).round() * 5;

  /// Examples of [kind], optionally tailored to the slot they're eaten in —
  /// the snack's protein is a yogurt or a bar, not a palm of chicken.
  static List<PortionExample> examples(PlateKind kind, {MealSlot? slot}) {
    if (slot == MealSlot.breakfast) {
      switch (kind) {
        case PlateKind.protein:
          // Breakfast is two portions, so the yogurt reads as the 200g tub.
          return const [
            PortionExample(1.5, '', 'eggs'),
            PortionExample(125, 'g', 'cottage 5%'),
            PortionExample(100, 'g', 'Greek yogurt 0%'),
          ];
        case PlateKind.carb:
          return const [
            PortionExample(2, '', 'slices bread'),
            PortionExample(1, '', 'pita'),
            PortionExample(1, '', 'fruit'),
          ];
        default:
          break;
      }
    }
    if (slot == MealSlot.lunch && kind == PlateKind.carb) {
      // Lunch is two carb portions, which is where the plan's own measures
      // land: 8 flat spoons of rice, or the same as 2 serving spoons.
      return const [
        PortionExample(4, '', 'flat spoons of rice'),
        PortionExample(1, '', 'serving spoon of rice',
            plural: 'serving spoons of rice'),
        PortionExample(75, 'g', 'pasta or ptitim'),
        PortionExample(1, '', 'small potato', plural: 'small potatoes'),
      ];
    }
    if (slot == MealSlot.snack && kind == PlateKind.protein) {
      return const [
        PortionExample(1, '', 'protein snack', plural: 'protein snacks'),
        PortionExample(200, 'g', 'Greek yogurt 0%'),
      ];
    }
    if (slot == MealSlot.dinner && kind == PlateKind.protein) {
      // A dinner's protein is often built from a couple of things rather than
      // one piece of meat, so eggs, cottage and a scoop sit alongside the meat.
      return const [
        PortionExample(5 / 6, '', 'palm of chicken', plural: 'palms of chicken'),
        PortionExample(0.5, '', 'palm of salmon', plural: 'palms of salmon'),
        PortionExample(1.5, '', 'eggs'),
        PortionExample(125, 'g', 'cottage 5%'),
        PortionExample(0.5, '', 'whey scoop', plural: 'whey scoops'),
      ];
    }
    switch (kind) {
      case PlateKind.protein:
        // Lunch. The plan anchors 220g cooked lean chicken at 3 portions, so
        // three reads as about two and a half palms. Salmon is richer, so its
        // palm goes further.
        return const [
          PortionExample(5 / 6, '', 'palm of chicken',
              plural: 'palms of chicken'),
          PortionExample(0.5, '', 'palm of salmon', plural: 'palms of salmon'),
        ];
      case PlateKind.carb:
        return const [
          PortionExample(1, '', 'fistful of rice', plural: 'fistfuls of rice'),
          PortionExample(2, '', 'slices bread'),
          PortionExample(1, '', 'fruit'),
        ];
      case PlateKind.fat:
        // Both the plan's own: 2 tsp of oil, or a flat tbsp of tahini.
        return const [
          PortionExample(2, 'tsp', 'oil'),
          PortionExample(1, 'tbsp', 'tahini'),
        ];
      case PlateKind.veg:
        return const [
          PortionExample(1, '', 'medium vegetable',
              plural: 'medium vegetables'),
          PortionExample(1, '', 'handful', plural: 'handfuls'),
          PortionExample(3, '', 'handfuls of leaves'),
        ];
      case PlateKind.treat:
        return const [
          PortionExample(1, '', 'chocolate row', plural: 'chocolate rows'),
          PortionExample(1, '', 'small bamba', plural: 'small bambas'),
          PortionExample(1, '', 'fruit'),
        ];
    }
  }
}
