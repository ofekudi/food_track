import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/food_provider.dart';
import '../models/food_entry.dart';
import '../models/favorite_item.dart';
import 'add_food_screen.dart';
import 'manage_favorites_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showNutritionDetails(BuildContext context, FoodEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meal Type: ${entry.mealType}'),
            const SizedBox(height: 8),
            Text('Calories: ${entry.calories} kcal'),
            const SizedBox(height: 8),
            Text('Protein: ${entry.protein}g'),
            const SizedBox(height: 8),
            Text('Carbs: ${entry.carbs}g'),
            const SizedBox(height: 8),
            Text('Fat: ${entry.fat}g'),
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${entry.notes}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEntryDetailsDialog(BuildContext context, FoodEntry entry) {
    showDialog(
      context: context,
      // barrierDismissible: false, // Prevent closing by tapping outside if needed
      builder: (ctx) => Dialog(
        // Use Dialog for more control over padding/shape if needed, or keep AlertDialog
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  24, 48, 24, 24), // Add top padding for close button
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Title --- (Moved from AlertDialog title)
                  Text(entry.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  // --- Content ---
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Meal Type: ${entry.mealType}'),
                        const SizedBox(height: 8),
                        Text('Calories: ${entry.calories} kcal'),
                        const SizedBox(height: 8),
                        Text('Protein: ${entry.protein}g'),
                        const SizedBox(height: 8),
                        Text('Carbs: ${entry.carbs}g'),
                        const SizedBox(height: 8),
                        Text('Fat: ${entry.fat}g'),
                        if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('Notes:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(entry.notes!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- Actions (Edit/Delete) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Edit Button (Left)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        onPressed: () {
                          Navigator.of(ctx).pop(); // Close dialog
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddFoodScreen(entryToEdit: entry),
                            ),
                          );
                        },
                      ),
                      // Delete Button (Right)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                        label: const Text('Delete',
                            style: TextStyle(color: Colors.redAccent)),
                        onPressed: () {
                          // Optionally show nested confirmation here or just delete
                          Navigator.of(ctx).pop(); // Close details dialog
                          context
                              .read<FoodProvider>()
                              .deleteFoodEntry(entry.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"${entry.name}" deleted.')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // --- Close Button (Top Right) ---
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Manage Favorites',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ManageFavoritesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: context.read<FoodProvider>().selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (selectedDate != null) {
                await context
                    .read<FoodProvider>()
                    .setSelectedDate(selectedDate);
              }
            },
          ),
        ],
      ),
      body: Consumer<FoodProvider>(
        builder: (context, foodProvider, child) {
          return Column(
            children: [
              _buildDailySummary(foodProvider.dailySummary),
              _buildQuickAddSection(context, foodProvider.favorites),
              Expanded(
                child: _buildFoodEntriesList(foodProvider.foodEntries),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddFoodScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuickAddSection(
      BuildContext context, List<FavoriteItem> favorites) {
    if (favorites.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Add',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: favorites.map((fav) {
              return ActionChip(
                avatar: const Icon(Icons.flash_on, size: 16),
                label: Text(fav.name),
                onPressed: () {
                  context.read<FoodProvider>().addFoodEntryFromFavorite(fav);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${fav.name}!')),
                  );
                },
              );
            }).toList(),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _buildDailySummary(Map<String, dynamic>? summary) {
    if (summary == null) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No entries for today'),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionInfo(
                  'Calories',
                  '${summary['total_calories']}',
                  Icons.local_fire_department,
                ),
                _buildNutritionInfo(
                  'Protein',
                  '${summary['total_protein']}g',
                  Icons.fitness_center,
                ),
                _buildNutritionInfo(
                  'Carbs',
                  '${summary['total_carbs']}g',
                  Icons.grain,
                ),
                _buildNutritionInfo(
                  'Fat',
                  '${summary['total_fat']}g',
                  Icons.water_drop,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Meal Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<FoodProvider>(
              builder: (context, foodProvider, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMealTypeInfo(
                      'Breakfast',
                      foodProvider.mealTypeCounts['Breakfast'] ?? 0,
                      Icons.breakfast_dining,
                    ),
                    _buildMealTypeInfo(
                      'Lunch',
                      foodProvider.mealTypeCounts['Lunch'] ?? 0,
                      Icons.lunch_dining,
                    ),
                    _buildMealTypeInfo(
                      'Dinner',
                      foodProvider.mealTypeCounts['Dinner'] ?? 0,
                      Icons.dinner_dining,
                    ),
                    _buildMealTypeInfo(
                      'Snack',
                      foodProvider.mealTypeCounts['Snack'] ?? 0,
                      Icons.cookie,
                    ),
                    _buildMealTypeInfo(
                      'Coffee',
                      foodProvider.mealTypeCounts['Coffee'] ?? 0,
                      Icons.coffee,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInfo(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMealTypeInfo(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodEntriesList(List<FoodEntry> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No food entries for today'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            title: Text(entry.name, style: TextStyle(fontSize: 16)),
            subtitle: null,
            trailing: Text(
              entry.mealType,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () {
              _showEntryDetailsDialog(context, entry);
            },
          ),
        );
      },
    );
  }
}
