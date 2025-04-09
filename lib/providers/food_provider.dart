import 'package:flutter/foundation.dart';
import '../db_helper.dart';
import '../models/food_entry.dart';
import '../models/favorite_item.dart';

class FoodProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<FoodEntry> _foodEntries = [];
  Map<String, dynamic>? _dailySummary;
  Map<String, int> _mealTypeCounts = {
    'Breakfast': 0,
    'Lunch': 0,
    'Dinner': 0,
    'Snack': 0,
    'Coffee': 0,
  };
  List<FavoriteItem> _favorites = [];
  DateTime _selectedDate = DateTime.now();

  List<FoodEntry> get foodEntries => _foodEntries;
  Map<String, dynamic>? get dailySummary => _dailySummary;
  Map<String, int> get mealTypeCounts => _mealTypeCounts;
  List<FavoriteItem> get favorites => _favorites;
  DateTime get selectedDate => _selectedDate;

  Future<void> loadFoodEntries() async {
    final entries = await _dbHelper.getFoodEntriesForDate(_selectedDate);
    _foodEntries = entries.map((e) => FoodEntry.fromMap(e)).toList();
    _dailySummary = await _dbHelper.getDailySummary(_selectedDate);
    _mealTypeCounts = await _dbHelper.getMealTypeCounts(_selectedDate);
    await loadFavorites();
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

  Future<void> loadFavorites() async {
    final favs = await _dbHelper.getFavorites();
    _favorites = favs.map((f) => FavoriteItem.fromMap(f)).toList();
  }

  Future<void> addFavorite({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required String mealType,
  }) async {
    await _dbHelper.addFavorite(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mealType: mealType,
    );
    await loadFavorites();
    notifyListeners();
  }

  Future<void> deleteFavorite(String id) async {
    await _dbHelper.deleteFavorite(id);
    await loadFavorites();
    notifyListeners();
  }

  Future<void> updateFavorite(FavoriteItem favorite) async {
    await _dbHelper.updateFavorite(favorite);
    await loadFavorites();
    notifyListeners();
  }

  Future<void> addFoodEntryFromFavorite(FavoriteItem favorite) async {
    await addFoodEntry(
      name: favorite.name,
      calories: favorite.calories,
      protein: favorite.protein,
      carbs: favorite.carbs,
      fat: favorite.fat,
      mealType: favorite.mealType,
      notes: 'Quick add',
    );
  }
}
