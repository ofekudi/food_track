import '../models/meal_slot.dart';

/// One concrete example of a portion, in a form that can be multiplied — so a
/// meal listing "3 protein" shows 225g of chicken rather than the 75g that one
/// portion is, and you never have to do the arithmetic yourself.
class PortionExample {
  final double amount;

  /// 'g', 'tsp', 'tbsp', or empty for countable things ("2 eggs").
  final String unit;
  final String label;

  const PortionExample(this.amount, this.unit, this.label);

  /// This example at [portions] portions, e.g. "225g chicken".
  String scaled(int portions) {
    final total = amount * portions;
    if (unit == 'g') {
      // Rounded to the nearest 5 — it's an eyeball measure, not a weigh-in.
      final grams = (total / 5).round() * 5;
      return '${grams}g $label';
    }
    final quantity = _format(total);
    return unit.isEmpty ? '$quantity $label' : '$quantity $unit $label';
  }

  static String _format(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    if ((value * 2) == (value * 2).roundToDouble()) {
      final whole = value.floor();
      return whole == 0 ? '½' : '$whole½';
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
  /// What [portions] of this are worth. Protein carries its gram figure too,
  /// since that's the number worth watching on a cut.
  ///
  /// The grams are the plan's own spec (10–15g per portion). Lean choices sit
  /// at the top of that or above — 75g of chicken breast is nearer 23g — so
  /// treat it as a floor, not a ceiling.
  static String worth(PlateKind kind, int portions) {
    switch (kind) {
      case PlateKind.protein:
        return '${_range(100, 130, portions)} cal · '
            '${_range(10, 15, portions)}g protein';
      case PlateKind.carb:
        return '${_range(100, 130, portions)} cal';
      case PlateKind.fat:
        return 'up to ${100 * portions} cal';
      case PlateKind.veg:
        return '${_range(100, 150, portions)}g';
      case PlateKind.treat:
        return '~${150 * portions} cal';
    }
  }

  static String _range(int low, int high, int portions) =>
      '${low * portions}\u2013${high * portions}';

  static List<PortionExample> examples(PlateKind kind) {
    switch (kind) {
      case PlateKind.protein:
        // The plan anchors 220g cooked lean chicken at 3 portions, so one is
        // ~75g — noticeably less than the palm-sized piece people picture.
        // Cottage and eggs are its own single-portion examples.
        return const [
          PortionExample(75, 'g', 'chicken'),
          PortionExample(100, 'g', 'cottage 5%'),
          PortionExample(2, '', 'eggs'),
        ];
      case PlateKind.carb:
        // 200g cooked rice (8 flat tbsp) = 2 portions, per the plan.
        return const [
          PortionExample(100, 'g', 'cooked rice'),
          PortionExample(2, '', 'slices bread'),
          PortionExample(1, '', 'fruit'),
        ];
      case PlateKind.fat:
        return const [
          PortionExample(2, 'tsp', 'oil'),
          PortionExample(1, 'tbsp', 'tahini'),
          PortionExample(2, 'tsp', 'mayo'),
        ];
      case PlateKind.veg:
        return const [
          PortionExample(1, '', 'medium vegetable'),
          PortionExample(1, '', 'handful'),
          PortionExample(3, '', 'handfuls of leaves'),
        ];
      case PlateKind.treat:
        return const [
          PortionExample(1, '', 'chocolate row'),
          PortionExample(1, '', 'small bamba'),
          PortionExample(1, '', 'fruit'),
        ];
    }
  }
}
