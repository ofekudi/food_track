class FavoriteItem {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String mealType;

  FavoriteItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.mealType,
  });

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id'] as String,
      name: map['name'] as String,
      calories: map['calories'] as int? ?? 0,
      protein: map['protein'] as double? ?? 0.0,
      carbs: map['carbs'] as double? ?? 0.0,
      fat: map['fat'] as double? ?? 0.0,
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
      'meal_type': mealType,
    };
  }
}
