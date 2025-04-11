import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/food_provider.dart';
import '../providers/settings_provider.dart';
import '../models/food_entry.dart';
import '../models/favorite_item.dart';
import '../models/add_entry_status.dart';
import 'add_food_screen.dart';
import 'manage_favorites_screen.dart';
import '../widgets/daily_summary_widget.dart';
import 'meal_analytics_screen.dart';
import 'preferences_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _quickAddScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Use Future.delayed to wait 1 second before checking
    Future.delayed(const Duration(seconds: 1), () {
      // Check if the widget is still mounted after the delay
      if (mounted) {
        _checkKitchenClosed();
      }
    });
  }

  void _checkKitchenClosed() {
    // Ensure the context is still mounted before proceeding
    if (!mounted) return;

    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    // Exit if the feature is not enabled
    if (!settingsProvider.stopEatingEnabled) return;

    final kitchenClosedTime = settingsProvider.kitchenClosedTime;
    final bannerTitle =
        settingsProvider.stopEatingTitle; // Get the selected title

    // Only proceed if a kitchen closed time is set (getter handles enabled state check)
    if (kitchenClosedTime != null) {
      final now = TimeOfDay.now();

      // Convert TimeOfDay to minutes since midnight for easy comparison
      final nowMinutes = now.hour * 60 + now.minute;
      final closedMinutes =
          kitchenClosedTime.hour * 60 + kitchenClosedTime.minute;

      if (nowMinutes >= closedMinutes) {
        // Show a themed and funnier dialog
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            // Get screen height for sizing
            // final screenHeight = MediaQuery.of(dialogContext).size.height; // Height constraint removed

            return AlertDialog(
              icon: Icon(
                Icons.bedtime_outlined, // Changed icon to bedtime
                color: Theme.of(dialogContext).colorScheme.primary,
                size: 40,
              ),
              title: Text(bannerTitle), // Use the dynamic title from settings
              content: Text(
                // Reverted content structure
                "This is just a feeling.\nNot a need.", // New subtitle
                textAlign: TextAlign.center,
                // Apply a larger text style but ensure normal weight
                style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                      fontWeight:
                          FontWeight.normal, // Explicitly set normal weight
                    ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: <Widget>[
                TextButton(
                  child: Text(
                    "Got It",
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.primary,
                      // Apply a larger text style for the button
                      fontSize: Theme.of(dialogContext)
                              .textTheme
                              .labelLarge
                              ?.fontSize ??
                          16.0,
                      fontWeight: FontWeight.bold, // Make it bolder too
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close the dialog
                  },
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            );
          },
        );
      }
    }
  }

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

  Future<void> _handleAddFromFavorite(
      BuildContext context, FavoriteItem fav) async {
    final foodProvider = context.read<FoodProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final limit = settingsProvider.getDailyLimitForMeal(fav.mealType);

    final status = await foodProvider.addFoodEntryFromFavorite(fav, limit);

    if (!mounted) return;

    switch (status) {
      case AddEntryStatus.Added:
        _handleSuccessfulAdd(context, fav.name);
        break;
      case AddEntryStatus.LimitExceeded:
        _showLimitExceededDialog(context, fav, limit);
        break;
      case AddEntryStatus.Error:
        _showErrorSnackbar(context, fav.name);
        break;
    }
  }

  Future<void> _showLimitExceededDialog(
      BuildContext context, FavoriteItem fav, int limit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily Limit Reached'),
        content: Text(
            'You\'ve reached your daily limit of $limit for ${fav.mealType}. Add "${fav.name}" anyway?'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add Anyway'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final foodProvider = context.read<FoodProvider>();
      final status = await foodProvider.addFoodEntryFromFavorite(fav, limit,
          forceAdd: true);

      if (!mounted) return;

      if (status == AddEntryStatus.Added) {
        _handleSuccessfulAdd(context, fav.name);
      } else {
        _showErrorSnackbar(context, fav.name);
      }
    }
  }

  void _handleSuccessfulAdd(BuildContext context, String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $itemName!')),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_quickAddScrollController.hasClients) {
        _quickAddScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackbar(BuildContext context, String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error adding $itemName. Please try again.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Food Track'),
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
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Meal Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MealAnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Preferences',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PreferencesScreen()),
              );
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        onPressed: () {
                          // Navigate to previous day
                          final prevDate =
                              selectedDate.subtract(const Duration(days: 1));
                          context
                              .read<FoodProvider>()
                              .setSelectedDate(prevDate);
                        },
                        tooltip: 'Previous day',
                      ),
                      InkWell(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: foodProvider.selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (selectedDate != null) {
                            await context
                                .read<FoodProvider>()
                                .setSelectedDate(selectedDate);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat.yMMMd().format(selectedDate),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        // Disable the forward arrow if we're already at today
                        onPressed: isToday
                            ? null
                            : () {
                                // Navigate to next day, but not beyond today
                                final nextDate =
                                    selectedDate.add(const Duration(days: 1));
                                // Make sure we don't go beyond today
                                if (nextDate.isBefore(today) ||
                                    nextDate.year == today.year &&
                                        nextDate.month == today.month &&
                                        nextDate.day == today.day) {
                                  context
                                      .read<FoodProvider>()
                                      .setSelectedDate(nextDate);
                                }
                              },
                        tooltip:
                            isToday ? 'Cannot go beyond today' : 'Next day',
                      ),
                    ],
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
          const SizedBox(height: 12),
          SingleChildScrollView(
            controller: _quickAddScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: favorites.map((fav) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                  child: ActionChip(
                    avatar: const Icon(Icons.flash_on, size: 16),
                    label: Text(fav.name),
                    onPressed: () => _handleAddFromFavorite(context, fav),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
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

  @override
  void dispose() {
    _quickAddScrollController.dispose();
    super.dispose();
  }
}
