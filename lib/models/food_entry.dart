import 'package:intl/intl.dart';

class FoodEntry {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? notes;
  final DateTime createdAt;
  final String mealType;
  final DateTime entryDate;

  FoodEntry({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.notes,
    required this.createdAt,
    required this.mealType,
    required this.entryDate,
  });

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    DateTime parsedEntryDate;
    try {
      parsedEntryDate =
          DateFormat('yyyy-MM-dd').parseStrict(map['entry_date'] as String);
    } catch (e) {
      try {
        DateTime createdAt = DateTime.parse(map['created_at'] as String);
        parsedEntryDate =
            DateTime(createdAt.year, createdAt.month, createdAt.day);
      } catch (_) {
        parsedEntryDate = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);
      }
    }

    return FoodEntry(
      id: map['id'] as String,
      name: map['name'] as String,
      calories: map['calories'] as int? ?? 0,
      protein: map['protein'] as double? ?? 0.0,
      carbs: map['carbs'] as double? ?? 0.0,
      fat: map['fat'] as double? ?? 0.0,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      mealType: map['meal_type'] as String? ?? 'Unknown',
      entryDate: parsedEntryDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'meal_type': mealType,
      'entry_date': DateFormat('yyyy-MM-dd').format(entryDate),
    };
  }
}
