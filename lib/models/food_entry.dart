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
  });

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    return FoodEntry(
      id: map['id'] as String,
      name: map['name'] as String,
      calories: map['calories'] as int,
      protein: map['protein'] as double,
      carbs: map['carbs'] as double,
      fat: map['fat'] as double,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      mealType: map['meal_type'] as String,
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
    };
  }
}
