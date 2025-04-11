import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../providers/settings_provider.dart';
import '../models/favorite_item.dart';
import '../models/food_entry.dart';
import '../models/add_entry_status.dart';

class AddFoodScreen extends StatefulWidget {
  final FavoriteItem? favoriteToEdit;
  final FoodEntry? entryToEdit;
  final DateTime targetDate;

  const AddFoodScreen({
    super.key,
    this.favoriteToEdit,
    this.entryToEdit,
    required this.targetDate,
  }) : assert(favoriteToEdit == null || entryToEdit == null,
            'Cannot edit both a favorite and an entry at the same time');

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedFoodName =
      widget.favoriteToEdit?.name ?? widget.entryToEdit?.name ?? '';
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _notesController = TextEditingController();
  final _nameFocusNode = FocusNode();
  String _selectedMealType = 'Breakfast';

  bool get _isEditingFavorite => widget.favoriteToEdit != null;
  bool get _isEditingEntry => widget.entryToEdit != null;
  bool get _isEditing => _isEditingFavorite || _isEditingEntry;

  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Coffee',
  ];

  @override
  void initState() {
    super.initState();

    if (_isEditingFavorite) {
      final fav = widget.favoriteToEdit!;
      _selectedFoodName = fav.name;
      _caloriesController.text = fav.calories.toString();
      _proteinController.text = fav.protein.toString();
      _carbsController.text = fav.carbs.toString();
      _fatController.text = fav.fat.toString();
      _selectedMealType = fav.mealType;
    } else if (_isEditingEntry) {
      final entry = widget.entryToEdit!;
      _selectedFoodName = entry.name;
      _caloriesController.text = entry.calories.toString();
      _proteinController.text = entry.protein.toString();
      _carbsController.text = entry.carbs.toString();
      _fatController.text = entry.fat.toString();
      _notesController.text = entry.notes ?? '';
      _selectedMealType = entry.mealType;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nameFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _notesController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final foodProvider = context.read<FoodProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      final name = _selectedFoodName;
      final calories = _caloriesController.text.isEmpty
          ? 0
          : int.parse(_caloriesController.text);
      final protein = _proteinController.text.isEmpty
          ? 0.0
          : double.parse(_proteinController.text);
      final carbs = _carbsController.text.isEmpty
          ? 0.0
          : double.parse(_carbsController.text);
      final fat =
          _fatController.text.isEmpty ? 0.0 : double.parse(_fatController.text);
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      if (_isEditingFavorite) {
        final updatedFavorite = FavoriteItem(
          id: widget.favoriteToEdit!.id,
          name: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          mealType: _selectedMealType,
        );
        await foodProvider.updateFavorite(updatedFavorite);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Favorite "$name" updated!')),
          );
          Navigator.pop(context);
        }
      } else if (_isEditingEntry) {
        final updatedEntry = FoodEntry(
          id: widget.entryToEdit!.id,
          createdAt: widget.entryToEdit!.createdAt,
          entryDate: widget.entryToEdit!.entryDate,
          name: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          mealType: _selectedMealType,
          notes: notes,
        );
        await foodProvider.updateFoodEntry(updatedEntry);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Entry "$name" updated!')),
          );
          Navigator.pop(context);
        }
      } else {
        final limit = settingsProvider.getDailyLimitForMeal(_selectedMealType);

        Future<AddEntryStatus> addAction({bool force = false}) {
          return foodProvider.addFoodEntry(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            mealType: _selectedMealType,
            notes: notes,
            entryDate: widget.targetDate,
            dailyLimit: limit,
            forceAdd: force,
          );
        }

        final initialStatus = await addAction();

        if (!mounted) return;

        if (initialStatus == AddEntryStatus.Added) {
          Navigator.pop(context);
        } else if (initialStatus == AddEntryStatus.LimitExceeded) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Daily Limit Reached'),
              content: Text(
                  'You\'ve reached your daily limit of $limit for $_selectedMealType. Add "$name" anyway?'),
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
            final forceStatus = await addAction(force: true);
            if (mounted) {
              if (forceStatus == AddEntryStatus.Added) {
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Error adding "$name". Please try again.')),
                );
              }
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding "$name". Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    if (_isEditingFavorite) {
      title = 'Edit Favorite';
    } else if (_isEditingEntry) {
      title = 'Edit Entry';
    } else {
      title = 'Add Food Entry';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text(
              'Add',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _selectedFoodName),
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  return await context
                      .read<FoodProvider>()
                      .getFoodSuggestions(textEditingValue.text);
                },
                onSelected: (String selection) {
                  _selectedFoodName = selection;
                  final favorites = context.read<FoodProvider>().favorites;
                  final matchingFavorite = favorites.firstWhere(
                    (favorite) => favorite.name == selection,
                    orElse: () => FavoriteItem(
                      id: '',
                      name: '',
                      calories: 0,
                      protein: 0,
                      carbs: 0,
                      fat: 0,
                      mealType: _selectedMealType,
                    ),
                  );

                  if (matchingFavorite.name.isNotEmpty) {
                    setState(() {
                      _caloriesController.text =
                          matchingFavorite.calories.toString();
                      _proteinController.text =
                          matchingFavorite.protein.toString();
                      _carbsController.text = matchingFavorite.carbs.toString();
                      _fatController.text = matchingFavorite.fat.toString();
                      _selectedMealType = matchingFavorite.mealType;
                    });
                  }
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    autofocus: !_isEditingFavorite && !_isEditingEntry,
                    decoration: const InputDecoration(
                      labelText: 'Food Name *',
                      border: OutlineInputBorder(),
                      helperText: 'Start typing to see suggestions',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a food name';
                      }
                      return null;
                    },
                    onChanged: (value) => _selectedFoodName = value,
                  );
                },
                optionsViewBuilder: (BuildContext context,
                    AutocompleteOnSelected<String> onSelected,
                    Iterable<String> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return ListTile(
                              title: Text(option),
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  border: OutlineInputBorder(),
                ),
                items: _mealTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMealType = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calories',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Carbs (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(
                        labelText: 'Fat (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!_isEditingFavorite)
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
