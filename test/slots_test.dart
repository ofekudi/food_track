import 'package:flutter_test/flutter_test.dart';
import 'package:food_track/constants/portion_guide.dart';
import 'package:food_track/models/day_mode.dart';
import 'package:food_track/models/day_summary.dart';
import 'package:food_track/models/day_timeline.dart';
import 'package:food_track/models/entry.dart';
import 'package:food_track/models/meal_slot.dart';

Entry entryAt(MealSlot slot, int hour, {String text = 'x'}) => Entry(
      id: '$slot-$hour',
      date: '2026-09-13',
      slot: slot,
      text: text,
      createdAt: DateTime(2026, 9, 13, hour),
    );

void main() {
  group('slot inference', () {
    test('maps the time of day to the likely slot', () {
      expect(MealSlot.forTime(DateTime(2026, 9, 13, 8)), MealSlot.breakfast);
      expect(MealSlot.forTime(DateTime(2026, 9, 13, 13)), MealSlot.lunch);
      expect(MealSlot.forTime(DateTime(2026, 9, 13, 16, 30)), MealSlot.snack);
      expect(MealSlot.forTime(DateTime(2026, 9, 13, 21)), MealSlot.dinner);
    });

    test('boundaries fall on the earlier slot', () {
      expect(MealSlot.forTime(DateTime(2026, 9, 13, 10, 59)), MealSlot.breakfast);
      expect(MealSlot.forTime(DateTime(2026, 9, 13, 11)), MealSlot.lunch);
    });
  });

  group('plates', () {
    int portionsOf(MealSlot slot, DayMode mode, PlateKind kind) => slot
        .plate(mode)
        .firstWhere((segment) => segment.kind == kind)
        .portions;

    test('weekday meals match the portions the plan writes', () {
      // Breakfast and dinner: 2P + 1C + 1F. Lunch: 3P + 2C + 1F.
      for (final slot in [MealSlot.breakfast, MealSlot.dinner]) {
        expect(portionsOf(slot, DayMode.normal, PlateKind.protein), 2);
        expect(portionsOf(slot, DayMode.normal, PlateKind.carb), 1);
        expect(portionsOf(slot, DayMode.normal, PlateKind.fat), 1);
      }
      expect(portionsOf(MealSlot.lunch, DayMode.normal, PlateKind.protein), 3);
      expect(portionsOf(MealSlot.lunch, DayMode.normal, PlateKind.carb), 2);
      expect(portionsOf(MealSlot.lunch, DayMode.normal, PlateKind.fat), 1);
    });

    test('the ring is drawn from the portion ratio', () {
      final plate = MealSlot.breakfast.plate(DayMode.normal);
      expect(plate.totalPortions, 4);
      expect(plate.fractionOf(plate.first), closeTo(0.5, 0.001));

      for (final mode in DayMode.values) {
        for (final slot in MealSlot.meals) {
          final segments = slot.plate(mode);
          final total = segments.fold<double>(
              0, (sum, segment) => sum + segments.fractionOf(segment));
          expect(total, closeTo(1.0, 0.001),
              reason: '${slot.name} on a ${mode.name} day');
        }
      }
    });

    test('an event dinner is the Mercedes plate: equal parts', () {
      final plate = MealSlot.dinner.plate(DayMode.event);
      expect(plate.map((s) => s.kind),
          containsAll([PlateKind.protein, PlateKind.carb, PlateKind.veg]));
      for (final segment in plate) {
        expect(plate.fractionOf(segment), closeTo(1 / 3, 0.001));
      }
    });

    test('the snack keeps the plan\'s treat allowance', () {
      final plate = MealSlot.snack.plate(DayMode.normal);
      expect(plate.map((s) => s.kind), contains(PlateKind.treat));
    });

    test('extras have no intended shape', () {
      expect(MealSlot.extras.plate(DayMode.normal), isEmpty);
      expect(MealSlot.extras.plate(DayMode.event), isEmpty);
    });
  });

  group('clean days', () {
    DaySummary summary({required Set<MealSlot> slots, required int extras}) =>
        DaySummary(
          date: DateTime(2026, 9, 13),
          filledSlots: slots,
          extrasCount: extras,
          mode: DayMode.normal,
        );

    test('a tracked day with no extras is clean', () {
      expect(summary(slots: {MealSlot.breakfast}, extras: 0).isClean, isTrue);
    });

    test('a single extra breaks the day', () {
      expect(summary(slots: MealSlot.meals.toSet(), extras: 1).isClean, isFalse);
    });

    test('a day with nothing logged is not clean', () {
      // Otherwise not using the app would look like success.
      expect(summary(slots: {}, extras: 0).isClean, isFalse);
    });
  });

  group('day timeline', () {
    test('an extra sorts between the meals it happened between', () {
      final items = <DayItem>[
        SlotItem(MealSlot.lunch, [entryAt(MealSlot.lunch, 13)]),
        SlotItem(MealSlot.dinner, [entryAt(MealSlot.dinner, 20)]),
        ExtraItem(entryAt(MealSlot.extras, 16, text: 'biscuits')),
      ]..sort((a, b) => a.sortMinutes.compareTo(b.sortMinutes));

      expect(items[1], isA<ExtraItem>());
    });

    test('an empty slot holds its usual place', () {
      final empty = SlotItem(MealSlot.breakfast, const []);
      expect(empty.sortMinutes, MealSlot.breakfast.defaultMinutes);
      expect(empty.isFilled, isFalse);
    });
  });

  group('calorie reference', () {
    const plan = MealSlot.planDailyCalories;

    int dayTotal(DayMode mode, int target) => MealSlot.meals
        .fold<int>(0, (sum, slot) => sum + (slot.calories(mode, target) ?? 0));

    test('a normal day is the plan, meal for meal', () {
      expect(MealSlot.breakfast.calories(DayMode.normal, plan), 470);
      expect(MealSlot.lunch.calories(DayMode.normal, plan), 720);
      expect(MealSlot.snack.calories(DayMode.normal, plan), 300);
      expect(MealSlot.dinner.calories(DayMode.normal, plan), 470);
      expect(dayTotal(DayMode.normal, plan), plan);
    });

    test('an event day is the plan, meal for meal', () {
      expect(MealSlot.breakfast.calories(DayMode.event, plan), 370);
      expect(MealSlot.lunch.calories(DayMode.event, plan), 470);
      expect(MealSlot.snack.calories(DayMode.event, plan), 150);
      expect(MealSlot.dinner.calories(DayMode.event, plan), 1000);
    });

    test('the stated figures agree with the portions they sit next to', () {
      // The two are written separately, so this is what stops a slot showing
      // a calorie figure its own plate can't account for.
      for (final mode in DayMode.values) {
        for (final slot in MealSlot.meals) {
          expect(
            slot.calories(mode, plan)!,
            closeTo(slot.portionCalories(mode), 30),
            reason: '${slot.name} on a ${mode.name} day',
          );
        }
      }
    });

    test('an event day banks its earlier slots into dinner', () {
      expect(MealSlot.breakfast.calories(DayMode.event, plan)!,
          lessThan(MealSlot.breakfast.calories(DayMode.normal, plan)!));
      expect(MealSlot.lunch.calories(DayMode.event, plan)!,
          lessThan(MealSlot.lunch.calories(DayMode.normal, plan)!));
      expect(MealSlot.dinner.calories(DayMode.event, plan)!,
          greaterThan(MealSlot.dinner.calories(DayMode.normal, plan)!));
      expect(dayTotal(DayMode.event, plan), closeTo(plan, 50));
    });

    test('raising the target scales every meal with it', () {
      expect(dayTotal(DayMode.normal, 2400), closeTo(2400, 20));
      expect(MealSlot.lunch.calories(DayMode.normal, 2400)!,
          greaterThan(MealSlot.lunch.calories(DayMode.normal, plan)!));
    });

    test('extras carry no reference figure', () {
      expect(MealSlot.extras.calories(DayMode.normal, plan), isNull);
    });
  });

  group('portion examples', () {
    String first(PlateKind kind, int portions) =>
        PortionGuide.examples(kind).first.scaled(portions);

    test('one portion of protein is three quarters of a palm', () {
      // The plan anchors 220g cooked chicken at 3 portions, so 3 reads as
      // roughly two palms.
      expect(first(PlateKind.protein, 1), '\u00be palm of chicken');
      expect(first(PlateKind.protein, 2), '1\u00bd palms of chicken');
      expect(first(PlateKind.protein, 3), '2\u00bc palms of chicken');
    });

    test('carbs scale by the cupped hand', () {
      expect(first(PlateKind.carb, 1), '1 cupped hand of rice');
      expect(first(PlateKind.carb, 2), '2 cupped hands of rice');
      expect(PortionGuide.examples(PlateKind.carb)[1].scaled(2),
          '4 slices bread');
    });

    test('grams stay grams where an object would not help', () {
      final breakfast =
          PortionGuide.examples(PlateKind.protein, slot: MealSlot.breakfast);
      expect(breakfast[1].scaled(1), '100g cottage 5%');
      expect(breakfast[1].scaled(2), '200g cottage 5%');
    });

    test('a meal offers fish as well as chicken', () {
      final meal = PortionGuide.examples(PlateKind.protein);
      // The plan lists 150g of salmon as three portions.
      expect(meal[1].scaled(3), '150g salmon');
      expect(meal[2].scaled(2), '2 cans of tuna');
    });

    test('breakfast protein is not a piece of chicken', () {
      final breakfast =
          PortionGuide.examples(PlateKind.protein, slot: MealSlot.breakfast);
      expect(breakfast.map((e) => e.label), isNot(contains('palm of chicken')));
      expect(breakfast.first.scaled(2), '4 eggs');
    });

    test('dinner can be a protein snack too', () {
      final dinner =
          PortionGuide.examples(PlateKind.protein, slot: MealSlot.dinner);
      expect(dinner.map((e) => e.label), contains('protein snack'));
    });

    test('the snack has its own kind of protein', () {
      final snack =
          PortionGuide.examples(PlateKind.protein, slot: MealSlot.snack);
      expect(snack.first.scaled(1), '1 protein snack');
      expect(snack.map((e) => e.label), isNot(contains('palm of chicken')));
    });

    test('worth is a single rounded figure, not a range', () {
      expect(PortionGuide.worth(PlateKind.protein, 1),
          '125 cal \u00b7 15g protein');
      expect(PortionGuide.worth(PlateKind.protein, 2),
          '250 cal \u00b7 25g protein');
      expect(PortionGuide.worth(PlateKind.carb, 2), '250 cal');
    });

    test('a snack\'s protein is richer than a meal\'s', () {
      // A protein yogurt or bar, not a piece of chicken.
      expect(PortionGuide.worth(PlateKind.protein, 1, slot: MealSlot.snack),
          '125 cal \u00b7 20g protein');
    });

    test('units are kept on the things that have them', () {
      expect(PortionGuide.examples(PlateKind.fat).first.scaled(1), '2 tsp oil');
      expect(
          PortionGuide.examples(PlateKind.protein, slot: MealSlot.breakfast)
              .first
              .scaled(2),
          '4 eggs');
    });
  });

  test('entries survive a round trip through the database shape', () {
    final entry = Entry(
      id: 'abc',
      date: '2026-09-13',
      slot: MealSlot.extras,
      text: 'biscuits',
      createdAt: DateTime(2026, 9, 13, 15, 30),
    );
    final restored = Entry.fromMap(entry.toMap());

    expect(restored.id, entry.id);
    expect(restored.slot, MealSlot.extras);
    expect(restored.text, 'biscuits');
    expect(restored.createdAt, entry.createdAt);
    expect(restored.minutesOfDay, 15 * 60 + 30);
  });
}
