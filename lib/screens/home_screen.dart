import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/food_provider.dart';
import '../models/food_entry.dart';
import '../models/favorite_item.dart';
import 'add_food_screen.dart';
import 'manage_favorites_screen.dart';
import '../widgets/daily_summary_widget.dart';

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
                          // Get current selected date for context
                          final selectedDate =
                              context.read<FoodProvider>().selectedDate;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddFoodScreen(
                                  entryToEdit: entry,
                                  targetDate: selectedDate // Pass date
                                  ),
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
        elevation: 0,
        scrolledUnderElevation: 0,
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
          final selectedDate = foodProvider.selectedDate;
          final today = DateTime.now();
          final isToday = selectedDate.year == today.year &&
              selectedDate.month == today.month &&
              selectedDate.day == today.day;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Always display the selected date
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 0),
                  child: Text(
                    DateFormat.yMMMd().format(selectedDate),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary),
                    textAlign: TextAlign.center,
                  ),
                ),
                DailySummaryWidget(summary: foodProvider.dailySummary),
                _buildQuickAddSection(context, foodProvider.favorites),
                _buildFoodEntriesList(foodProvider.foodEntries),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Get the currently selected date from the provider
          final selectedDate = context.read<FoodProvider>().selectedDate;
          Navigator.push(
            context,
            MaterialPageRoute(
              // Pass the selected date to AddFoodScreen
              builder: (context) => AddFoodScreen(targetDate: selectedDate),
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

  Widget _buildFoodEntriesList(List<FoodEntry> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No food entries for today'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
