import 'package:flutter/foundation.dart';
import '../db_helper.dart';
import '../models/food_entry.dart';
import '../models/favorite_item.dart';
import '../models/add_entry_status.dart';

class FoodProvider with ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<FoodEntry> _foodEntries = [];
  List<FavoriteItem> _favorites = [];
  List<Map<String, dynamic>> _uniqueFoodItems = [];
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
  List<Map<String, dynamic>> get uniqueFoodItems => _uniqueFoodItems;

  Future<void> loadFoodEntries() async {
    final entriesData = await _loadRawEntriesForDate(_selectedDate);
    _foodEntries = entriesData.map((e) => FoodEntry.fromMap(e)).toList();

    _calculateMealTypeCounts();
    _calculateDailySummary();
    await loadFavorites();
    await loadUniqueFoodItems();

    notifyListeners();

    // Load all entries for analytics if not already loaded
    if (!_hasLoadedAllEntries) {
      _loadAllEntries(); // Start loading in background
    }
  }

  Future<List<Map<String, dynamic>>> _loadRawEntriesForDate(
      DateTime date) async {
    // Only fetch raw entries from DB here
    return await _dbHelper.getFoodEntriesForDate(date);
    // Daily summary calculation moved to _calculateDailySummary
    // Meal type counts calculation moved to _calculateMealTypeCounts
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

  // Helper to check limit
  bool _checkLimit(String mealType, int limit) {
    if (limit <= 0) return true; // 0 or less means no limit
    return (_mealTypeCounts[mealType] ?? 0) < limit;
  }

  Future<AddEntryStatus> addFoodEntry({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required String mealType,
    String? notes,
    required DateTime entryDate,
    required int dailyLimit,
    bool forceAdd = false,
  }) async {
    // Check limit only if entryDate is the same as selectedDate
    if (entryDate.year == _selectedDate.year &&
        entryDate.month == _selectedDate.month &&
        entryDate.day == _selectedDate.day) {
      if (!_checkLimit(mealType, dailyLimit) && !forceAdd) {
        return AddEntryStatus.LimitExceeded;
      }
    }

    try {
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
      await loadFoodEntries(); // Reload data after adding
      return AddEntryStatus.Added;
    } catch (e) {
      if (kDebugMode) {
        print("Error adding food entry: $e");
      }
      return AddEntryStatus.Error;
    }
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

  Future<AddEntryStatus> addFoodEntryFromFavorite(
      FavoriteItem favorite, int dailyLimit,
      {bool forceAdd = false}) async {
    // Check limit first
    if (!_checkLimit(favorite.mealType, dailyLimit) && !forceAdd) {
      return AddEntryStatus.LimitExceeded;
    }

    // Proceed to add if limit is okay or forced
    final status = await addFoodEntry(
      name: favorite.name,
      calories: favorite.calories,
      protein: favorite.protein,
      carbs: favorite.carbs,
      fat: favorite.fat,
      mealType: favorite.mealType,
      notes: null,
      entryDate: _selectedDate,
      dailyLimit: dailyLimit, // Pass limit (though already checked)
      forceAdd: true, // Force add here as we already checked the limit
    );

    if (status == AddEntryStatus.Added) {
      // Move the used favorite to the start only if added successfully
      await moveFavoriteToStart(favorite.id);
    }
    return status;
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

  // New method to calculate meal counts from the loaded list
  void _calculateMealTypeCounts() {
    _mealTypeCounts = {
      'Breakfast': 0,
      'Lunch': 0,
      'Dinner': 0,
      'Snack': 0,
      'Coffee': 0,
    };
    for (var entry in _foodEntries) {
      if (_mealTypeCounts.containsKey(entry.mealType)) {
        _mealTypeCounts[entry.mealType] =
            (_mealTypeCounts[entry.mealType] ?? 0) + 1;
      }
    }
  }

  Future<void> loadUniqueFoodItems() async {
    _uniqueFoodItems = await _dbHelper.getUniqueFoodItems();
  }

  Future<AddEntryStatus> addFoodEntryFromUniqueItem(
      Map<String, dynamic> itemData, int dailyLimit,
      {bool forceAdd = false, DateTime? targetDate}) async {
    final dateToAdd = targetDate ?? _selectedDate;
    final mealType = itemData['meal_type'] as String? ?? 'Snack';
    final name = itemData['name'] as String? ?? 'Unknown Item';

    bool limitCheckApplies = dateToAdd.year == _selectedDate.year &&
        dateToAdd.month == _selectedDate.month &&
        dateToAdd.day == _selectedDate.day;

    if (limitCheckApplies && !_checkLimit(mealType, dailyLimit) && !forceAdd) {
      return AddEntryStatus.LimitExceeded;
    }

    final status = await addFoodEntry(
      name: name,
      calories: itemData['calories'] as int? ?? 0,
      protein: (itemData['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (itemData['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (itemData['fat'] as num?)?.toDouble() ?? 0.0,
      mealType: mealType,
      notes: null,
      entryDate: dateToAdd,
      dailyLimit: dailyLimit,
      forceAdd: true,
    );

    return status;
  }

  // New method to delete all entries by name
  Future<int> deleteAllEntriesByName(String name) async {
    final count = await _dbHelper.deleteAllEntriesByName(name);
    if (count > 0) {
      // Reload data to reflect changes
      await loadFoodEntries(); // This also reloads unique items
    }
    return count;
  }
}
