import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class DailyLimitScreen extends StatefulWidget {
  const DailyLimitScreen({super.key});

  @override
  State<DailyLimitScreen> createState() => _DailyLimitScreenState();
}

class _DailyLimitScreenState extends State<DailyLimitScreen> {
  late Map<String, TextEditingController> _controllers;
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
    final settingsProvider = context.read<SettingsProvider>();
    _controllers = {
      for (var type in _mealTypes)
        type: TextEditingController(
          text: settingsProvider.getDailyLimitForMeal(type).toString(),
        )
    };

    // Add listener to save changes immediately
    for (var controller in _controllers.values) {
      controller.addListener(_saveLimits);
    }
  }

  void _saveLimits() {
    final settingsProvider = context.read<SettingsProvider>();
    _controllers.forEach((mealType, controller) {
      final limit = int.tryParse(controller.text) ?? 0;
      // Only update if the value has actually changed from the provider's perspective
      if (settingsProvider.getDailyLimitForMeal(mealType) != limit) {
        settingsProvider.setDailyLimit(mealType, limit);
      }
    });
  }

  @override
  void dispose() {
    // Remove listeners and dispose controllers
    for (var controller in _controllers.values) {
      controller.removeListener(_saveLimits);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Meal Limits'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _mealTypes.length,
        itemBuilder: (context, index) {
          final mealType = _mealTypes[index];
          final controller = _controllers[mealType]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    mealType,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                    onChanged: (value) {
                      // Trigger listener indirectly via controller changes
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
