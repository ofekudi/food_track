import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/food_provider.dart';
import '../models/food_entry.dart';
import 'add_food_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Tracker'),
        actions: [
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

  Widget _buildFoodEntriesList(List<FoodEntry> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No food entries for today'),
      );
    }

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(entry.name),
            subtitle: Text(
              '${entry.calories} kcal • ${entry.mealType}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.protein}g P • ${entry.carbs}g C • ${entry.fat}g F',
                  style: const TextStyle(fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    context.read<FoodProvider>().deleteFoodEntry(entry.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
