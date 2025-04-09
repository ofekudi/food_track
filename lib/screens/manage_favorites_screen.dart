import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../models/favorite_item.dart';
import '../screens/add_food_screen.dart';

class ManageFavoritesScreen extends StatelessWidget {
  const ManageFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Favorites'),
      ),
      body: Consumer<FoodProvider>(
        builder: (context, foodProvider, child) {
          final favorites = foodProvider.favorites;

          if (favorites.isEmpty) {
            return const Center(
              child: Text('You haven\'t saved any favorites yet.'),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final fav = favorites[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(fav.name),
                  subtitle: Text(
                      '${fav.calories}kcal • ${fav.protein}P/${fav.carbs}C/${fav.fat}F • ${fav.mealType}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    tooltip: 'Delete Favorite',
                    onPressed: () {
                      // Show confirmation dialog before deleting
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: Text(
                              'Are you sure you want to delete "${fav.name}" from your favorites?'),
                          actions: [
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                            TextButton(
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.redAccent)),
                              onPressed: () {
                                context
                                    .read<FoodProvider>()
                                    .deleteFavorite(fav.id);
                                Navigator.of(ctx).pop(); // Close the dialog
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('"${fav.name}" deleted.')),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    // Get the current date from provider
                    final selectedDate =
                        context.read<FoodProvider>().selectedDate;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFoodScreen(
                          favoriteToEdit: fav,
                          targetDate: selectedDate, // Pass the date
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
