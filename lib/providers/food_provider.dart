import 'package:flutter/foundation.dart';
import '../db_helper.dart';
import '../models/food_entry.dart';

class FoodProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<FoodEntry> _foodEntries = [];
  Map<String, dynamic>? _dailySummary;
  DateTime _selectedDate = DateTime.now();

  List<FoodEntry> get foodEntries => _foodEntries;
  Map<String, dynamic>? get dailySummary => _dailySummary;
  DateTime get selectedDate => _selectedDate;

  Future<void> loadFoodEntries() async {
    final entries = await _dbHelper.getFoodEntriesForDate(_selectedDate);
    _foodEntries = entries.map((e) => FoodEntry.fromMap(e)).toList();
    _dailySummary = await _dbHelper.getDailySummary(_selectedDate);
    notifyListeners();
  }

  Future<void> addFoodEntry({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required String mealType,
    String? notes,
  }) async {
    await _dbHelper.addFoodEntry(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mealType: mealType,
      notes: notes,
    );
    await loadFoodEntries();
  }

  Future<void> deleteFoodEntry(String id) async {
    await _dbHelper.deleteFoodEntry(id);
    await loadFoodEntries();
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await loadFoodEntries();
  }

  Future<List<FoodEntry>> searchFoodEntries(String query) async {
    final results = await _dbHelper.searchFoodEntries(query);
    return results.map((e) => FoodEntry.fromMap(e)).toList();
  }
}
