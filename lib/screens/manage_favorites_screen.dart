import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../models/favorite_item.dart';
import '../models/food_entry.dart';
import '../screens/add_food_screen.dart';

class ManageFavoritesScreen extends StatefulWidget {
  const ManageFavoritesScreen({super.key});

  @override
  State<ManageFavoritesScreen> createState() => _ManageFavoritesScreenState();
}

class _ManageFavoritesScreenState extends State<ManageFavoritesScreen> {
  List<String>? _availableItems;

  @override
  void initState() {
    super.initState();
    _updateAvailableItems();
  }

  Future<void> _updateAvailableItems() async {
    final items = await context.read<FoodProvider>().getNonFavoritedItems();
    if (mounted) {
      setState(() {
        _availableItems = items;
      });
    }
  }

  void _showAddFromDatabaseDialog(BuildContext context) async {
    final foodProvider = context.read<FoodProvider>();
    final nonFavoritedItems = await foodProvider.getNonFavoritedItems();

    if (!context.mounted) return;
    if (nonFavoritedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more items to add to favorites'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add from Database',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select items from your most used foods:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: nonFavoritedItems.length,
                  itemBuilder: (context, index) {
                    final item = nonFavoritedItems[index];
                    return ListTile(
                      title: Text(item),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () async {
                          final entries =
                              await foodProvider.searchFoodEntries(item);
                          if (entries.isNotEmpty) {
                            final mostRecent = entries.first;
                            await foodProvider.addFavorite(
                              name: mostRecent.name,
                              calories: mostRecent.calories,
                              protein: mostRecent.protein,
                              carbs: mostRecent.carbs,
                              fat: mostRecent.fat,
                              mealType: mostRecent.mealType,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              _updateAvailableItems(); // Update available items after adding
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${mostRecent.name} added to favorites'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                              onPressed: () async {
                                await context
                                    .read<FoodProvider>()
                                    .deleteFavorite(fav.id);
                                if (context.mounted) {
                                  Navigator.of(ctx).pop();
                                  _updateAvailableItems(); // Update available items after deletion
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('"${fav.name}" deleted.')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFoodScreen(
                          favoriteToEdit: fav,
                          targetDate: context.read<FoodProvider>().selectedDate,
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
      floatingActionButton:
          _availableItems != null && _availableItems!.isNotEmpty
              ? FloatingActionButton(
                  onPressed: () => _showAddFromDatabaseDialog(context),
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }
}
