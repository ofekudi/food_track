import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../providers/settings_provider.dart';
import '../models/add_entry_status.dart';
import 'add_food_screen.dart'; // Import AddFoodScreen

class SelectFoodScreen extends StatefulWidget {
  final DateTime targetDate;

  const SelectFoodScreen({super.key, required this.targetDate});

  @override
  State<SelectFoodScreen> createState() => _SelectFoodScreenState();
}

class _SelectFoodScreenState extends State<SelectFoodScreen> {
  String _searchTerm = '';
  List<Map<String, dynamic>> _filteredItems = [];
  late Offset _tapPosition; // Store tap position for the menu

  @override
  void initState() {
    super.initState();
    // Initialize filtered list with all unique items from provider
    _filteredItems = context.read<FoodProvider>().uniqueFoodItems;
  }

  void _filterItems(String query) {
    final allItems = context.read<FoodProvider>().uniqueFoodItems;
    setState(() {
      _searchTerm = query;
      if (query.isEmpty) {
        _filteredItems = allItems;
      } else {
        _filteredItems = allItems
            .where((item) => (item['name'] as String? ?? '')
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _selectItem(
      BuildContext context, Map<String, dynamic> itemData) async {
    final foodProvider = context.read<FoodProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final mealType =
        itemData['meal_type'] as String? ?? 'Snack'; // Use default if needed
    final limit = settingsProvider.getDailyLimitForMeal(mealType);
    final itemName = itemData['name'] as String? ?? 'Selected Item';

    // Use the new provider method
    final status = await foodProvider.addFoodEntryFromUniqueItem(
      itemData,
      limit,
      targetDate: widget.targetDate,
    );

    if (!mounted) return;

    // Handle status (similar logic to before)
    switch (status) {
      case AddEntryStatus.Added:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Added "$itemName" for ${DateFormat.yMd().format(widget.targetDate)}!')),
        );
        Navigator.pop(context); // Go back after adding
        break;
      case AddEntryStatus.LimitExceeded:
        _showLimitExceededDialog(context, itemData, limit);
        break;
      case AddEntryStatus.Error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error adding "$itemName". Please try again.')),
        );
        break;
    }
  }

  Future<void> _showLimitExceededDialog(
      BuildContext context, Map<String, dynamic> itemData, int limit) async {
    final foodProvider = context.read<FoodProvider>();
    final mealType = itemData['meal_type'] as String? ?? 'Snack';
    final itemName = itemData['name'] as String? ?? 'Selected Item';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily Limit Reached'),
        content: Text(
            'You\'ve reached your daily limit of $limit for $mealType. Add "$itemName" anyway?'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true), // Confirm
            child: const Text('Add Anyway'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false), // Cancel
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Retry adding, forcing it
      final status = await foodProvider.addFoodEntryFromUniqueItem(
        itemData,
        limit,
        targetDate: widget.targetDate,
        forceAdd: true,
      );

      if (!mounted) return;

      if (status == AddEntryStatus.Added) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Added "$itemName" for ${DateFormat.yMd().format(widget.targetDate)}!')),
        );
        Navigator.pop(context); // Go back after adding
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error adding "$itemName". Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes in uniqueFoodItems
    final allUniqueItems = context.watch<FoodProvider>().uniqueFoodItems;

    // Update filtered list if the underlying provider list changes
    // This handles cases where items might be added/updated elsewhere
    if (_searchTerm.isEmpty && _filteredItems.length != allUniqueItems.length) {
      _filteredItems = allUniqueItems;
    } else if (_searchTerm.isNotEmpty) {
      _filteredItems = allUniqueItems
          .where((item) => (item['name'] as String? ?? '')
              .toLowerCase()
              .contains(_searchTerm.toLowerCase()))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Item'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterItems,
              decoration: InputDecoration(
                labelText: 'Search All Past Items',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          // Add the "Create New Item" button
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create New Item'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40), // Make button wider
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () async {
                // Navigate to AddFoodScreen
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddFoodScreen(targetDate: widget.targetDate),
                  ),
                );
                // If AddFoodScreen popped with true (meaning success), pop this screen too
                if (result == true && mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Text(_searchTerm.isEmpty
                        ? 'No past food items found.'
                        : 'No items match "$_searchTerm".'),
                  )
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final name = item['name'] as String? ?? 'N/A';
                      final calories = item['calories'] as int? ?? 0;
                      final protein =
                          (item['protein'] as num?)?.toDouble() ?? 0.0;
                      final carbs = (item['carbs'] as num?)?.toDouble() ?? 0.0;
                      final fat = (item['fat'] as num?)?.toDouble() ?? 0.0;
                      final mealType = item['meal_type'] as String? ?? 'N/A';

                      final foodProvider = context.read<FoodProvider>();

                      return GestureDetector(
                        onTapDown: (details) {
                          _tapPosition = details.globalPosition;
                        },
                        onLongPress: () {
                          final RenderBox overlay = Overlay.of(context)
                              .context
                              .findRenderObject()! as RenderBox;
                          showMenu(
                            context: context,
                            position: RelativeRect.fromRect(
                                _tapPosition &
                                    const Size(
                                        40, 40), // Small rect at tap position
                                Offset.zero &
                                    overlay.size // Bigger rect entire screen
                                ),
                            items: <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Edit')),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: ListTile(
                                    leading: Icon(Icons.delete_forever_outlined,
                                        color: Colors.redAccent),
                                    title: Text('Delete All Entries',
                                        style: TextStyle(
                                            color: Colors.redAccent))),
                              ),
                            ],
                            elevation: 8.0,
                          ).then<void>((String? newValue) {
                            if (newValue == null)
                              return; // Return if menu dismissed

                            if (newValue == 'edit') {
                              // Navigate to AddFoodScreen for editing
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddFoodScreen(
                                    targetDate: widget.targetDate,
                                    itemDataToEdit: item,
                                  ),
                                ),
                              );
                            } else if (newValue == 'delete') {
                              // Show delete confirmation dialog
                              showDialog(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  title: Text('Delete All "$name"?'),
                                  content: const Text(
                                      'This will delete ALL past entries for this food item. This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogCtx).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(dialogCtx)
                                            .pop(); // Close dialog
                                        final count = await foodProvider
                                            .deleteAllEntriesByName(name);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Deleted $count entries for "$name".')),
                                          );
                                        }
                                      },
                                      child: const Text('Delete All',
                                          style: TextStyle(
                                              color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          });
                        },
                        // The actual ListTile
                        child: ListTile(
                          title: Text(name),
                          subtitle: null,
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () => _selectItem(context, item),
                          // Long press handled by GestureDetector
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
