import 'package:flutter/foundation.dart';
import '../db_helper.dart';
import '../models/food_entry.dart';
import '../models/favorite_item.dart';

class FoodProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<FoodEntry> _foodEntries = [];
  List<FavoriteItem> _favorites = [];
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _dailySummary;
  Map<String, int> _mealTypeCounts = {
    'Breakfast': 0,
    'Lunch': 0,
    'Dinner': 0,
    'Snack': 0,
    'Coffee': 0,
  };
  // Added for analytics
  List<FoodEntry> _allFoodEntries = [];
  bool _hasLoadedAllEntries = false;

  List<FoodEntry> get foodEntries => _foodEntries;
  Map<String, dynamic>? get dailySummary => _dailySummary;
  Map<String, int> get mealTypeCounts => _mealTypeCounts;
  List<FavoriteItem> get favorites => _favorites;
  DateTime get selectedDate => _selectedDate;

  Future<void> loadFoodEntries() async {
    _foodEntries = await _loadEntriesForDate(_selectedDate);
    await loadFavorites();
    _calculateDailySummary();
    notifyListeners();

    // Load all entries for analytics if not already loaded
    if (!_hasLoadedAllEntries) {
      _loadAllEntries();
    }
  }

  Future<void> _loadAllEntries() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('food_entries');

    _allFoodEntries = List.generate(maps.length, (i) {
      return FoodEntry.fromMap(maps[i]);
    });

    _hasLoadedAllEntries = true;
    notifyListeners();
  }

  // Synchronous method to get all entries
  List<FoodEntry> getAllFoodEntries() {
    // If not loaded yet, return empty list (will be updated later)
    return _allFoodEntries;
  }

  Future<void> addFoodEntry({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required String mealType,
    String? notes,
    required DateTime entryDate,
  }) async {
    await _dbHelper.addFoodEntry(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      mealType: mealType,
      notes: notes,
      entryDate: entryDate,
    );
    await loadFoodEntries();
  }

  Future<void> deleteFoodEntry(String id) async {
    await _dbHelper.deleteFoodEntry(id);
    await loadFoodEntries();
  }

  Future<void> updateFoodEntry(FoodEntry entry) async {
    await _dbHelper.updateFoodEntry(entry);
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

  Future<void> moveFavoriteToStart(String favoriteId) async {
    // Find the favorite item
    final index = _favorites.indexWhere((fav) => fav.id == favoriteId);
    if (index > 0) {
      // Only move if it's not already at the start
      final favorite = _favorites.removeAt(index);
      _favorites.insert(0, favorite);
      notifyListeners();
    }
  }

  Future<void> addFoodEntryFromFavorite(FavoriteItem favorite) async {
    await addFoodEntry(
      name: favorite.name,
      calories: favorite.calories,
      protein: favorite.protein,
      carbs: favorite.carbs,
      fat: favorite.fat,
      mealType: favorite.mealType,
      notes: null,
      entryDate: _selectedDate,
    );
    // Move the used favorite to the start
    await moveFavoriteToStart(favorite.id);
  }

  // Get sorted food suggestions based on frequency
  Future<List<String>> getFoodSuggestions(String query) async {
    if (query.isEmpty) {
      // Get top 5 most used items from all entries
      final frequencies = await _dbHelper.getAllFoodFrequencies();
      final sortedEntries = frequencies.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sortedEntries.take(5).map((e) => e.key).toList();
    }

    // Search through all food names in the database
    return _dbHelper.searchFoodNames(query);
  }

  // Get non-favorited items from database
  Future<List<String>> getNonFavoritedItems() async {
    final allItems = await _dbHelper.getAllFoodFrequencies();
    final nonFavorited = allItems.keys
        .where((name) => !_favorites
            .any((fav) => fav.name.toLowerCase() == name.toLowerCase()))
        .toList()
      ..sort((a, b) => (allItems[b] ?? 0).compareTo(allItems[a] ?? 0));
    return nonFavorited;
  }

  void _calculateDailySummary() {
    if (_foodEntries.isEmpty) {
      _dailySummary = null;
      return;
    }

    int totalCalories = 0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;

    for (var entry in _foodEntries) {
      totalCalories += entry.calories;
      totalProtein += entry.protein;
      totalCarbs += entry.carbs;
      totalFat += entry.fat;
    }

    _dailySummary = {
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fat': totalFat,
    };
  }

  Future<List<FoodEntry>> _loadEntriesForDate(DateTime date) async {
    final entries = await _dbHelper.getFoodEntriesForDate(date);
    _dailySummary = await _dbHelper.getDailySummary(date);
    _mealTypeCounts = await _dbHelper.getMealTypeCounts(date);
    return entries.map((e) => FoodEntry.fromMap(e)).toList();
  }
}
