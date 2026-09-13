import 'package:intl/intl.dart';
import 'meal_slot.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

String formatDay(DateTime date) => _dateFormat.format(date);

/// One thing eaten, in one slot, on one day. Deliberately thin: no hunger, no
/// portions, no grams — what was eaten and where it went is the whole record.
class Entry {
  final String id;
  final String date; // 'yyyy-MM-dd'
  final MealSlot slot;
  final String text;
  final DateTime createdAt;

  Entry({
    required this.id,
    required this.date,
    required this.slot,
    required this.text,
    required this.createdAt,
  });

  /// Minutes from midnight, used to lay the day out in the order it happened.
  int get minutesOfDay => createdAt.hour * 60 + createdAt.minute;

  factory Entry.fromMap(Map<String, dynamic> map) => Entry(
        id: map['id'] as String,
        date: map['date'] as String,
        slot: MealSlot.fromString(map['slot'] as String?),
        text: map['text'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'slot': slot.name,
        'text': text,
        'created_at': createdAt.toIso8601String(),
      };
}
