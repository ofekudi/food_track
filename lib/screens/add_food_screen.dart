import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../models/favorite_item.dart';

class AddFoodScreen extends StatefulWidget {
  final FavoriteItem? favoriteToEdit;

  const AddFoodScreen({super.key, this.favoriteToEdit});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _notesController = TextEditingController();
  final _nameFocusNode = FocusNode();
  String _selectedMealType = 'Breakfast';

  bool get _isEditing => widget.favoriteToEdit != null;

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

    if (_isEditing) {
      final fav = widget.favoriteToEdit!;
      _nameController.text = fav.name;
      _caloriesController.text = fav.calories.toString();
      _proteinController.text = fav.protein.toString();
      _carbsController.text = fav.carbs.toString();
      _fatController.text = fav.fat.toString();
      _selectedMealType = fav.mealType;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nameFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _notesController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Favorite' : 'Add Food Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                autofocus: !_isEditing,
                decoration: const InputDecoration(
                  labelText: 'Food Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a food name';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
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
              if (!_isEditing)
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final provider = context.read<FoodProvider>();
                    final name = _nameController.text;
                    final calories = _caloriesController.text.isEmpty
                        ? 0
                        : int.parse(_caloriesController.text);
                    final protein = _proteinController.text.isEmpty
                        ? 0.0
                        : double.parse(_proteinController.text);
                    final carbs = _carbsController.text.isEmpty
                        ? 0.0
                        : double.parse(_carbsController.text);
                    final fat = _fatController.text.isEmpty
                        ? 0.0
                        : double.parse(_fatController.text);

                    if (_isEditing) {
                      final updatedFavorite = FavoriteItem(
                        id: widget.favoriteToEdit!.id,
                        name: name,
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        mealType: _selectedMealType,
                      );
                      await provider.updateFavorite(updatedFavorite);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Favorite "$name" updated!')),
                        );
                        Navigator.pop(context);
                      }
                    } else {
                      await provider.addFoodEntry(
                        name: name,
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                        mealType: _selectedMealType,
                        notes: _notesController.text.isEmpty
                            ? null
                            : _notesController.text,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _isEditing ? 'Update Favorite' : 'Add Food Entry',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.favorite_border, size: 18),
                    label: const Text('Save as Favorite'),
                    onPressed: () {
                      if (_nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please enter a food name to save as favorite.')),
                        );
                        return;
                      }
                      context.read<FoodProvider>().addFavorite(
                            name: _nameController.text,
                            calories: _caloriesController.text.isEmpty
                                ? 0
                                : int.parse(_caloriesController.text),
                            protein: _proteinController.text.isEmpty
                                ? 0.0
                                : double.parse(_proteinController.text),
                            carbs: _carbsController.text.isEmpty
                                ? 0.0
                                : double.parse(_carbsController.text),
                            fat: _fatController.text.isEmpty
                                ? 0.0
                                : double.parse(_fatController.text),
                            mealType: _selectedMealType,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                '${_nameController.text} saved as favorite!')),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
