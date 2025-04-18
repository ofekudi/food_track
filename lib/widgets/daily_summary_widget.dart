import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';
import '../providers/settings_provider.dart';

class DailySummaryWidget extends StatefulWidget {
  final Map<String, dynamic>? summary;
  // Meal type counts will be accessed via Provider within the build method

  const DailySummaryWidget({super.key, required this.summary});

  @override
  State<DailySummaryWidget> createState() => _DailySummaryWidgetState();
}

class _DailySummaryWidgetState extends State<DailySummaryWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildMealDistributionPage(BuildContext context) {
    // Access mealTypeCounts using Provider
    final mealTypeCounts = context.watch<FoodProvider>().mealTypeCounts;
    // Access SettingsProvider
    final settingsProvider = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meal Distribution',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMealTypeInfo(
                context,
                'Breakfast',
                mealTypeCounts['Breakfast'] ?? 0,
                Icons.breakfast_dining,
                settingsProvider.getDailyLimitForMeal('Breakfast'),
              ),
              _buildMealTypeInfo(
                context,
                'Lunch',
                mealTypeCounts['Lunch'] ?? 0,
                Icons.lunch_dining,
                settingsProvider.getDailyLimitForMeal('Lunch'),
              ),
              _buildMealTypeInfo(
                context,
                'Dinner',
                mealTypeCounts['Dinner'] ?? 0,
                Icons.dinner_dining,
                settingsProvider.getDailyLimitForMeal('Dinner'),
              ),
              _buildMealTypeInfo(
                context,
                'Snack',
                mealTypeCounts['Snack'] ?? 0,
                Icons.cookie,
                settingsProvider.getDailyLimitForMeal('Snack'),
              ),
              _buildMealTypeInfo(
                context,
                'Coffee',
                mealTypeCounts['Coffee'] ?? 0,
                Icons.coffee,
                settingsProvider.getDailyLimitForMeal('Coffee'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionPage(
      BuildContext context, Map<String, dynamic> summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrition Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
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
        ),
      ],
    );
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < 2; i++) {
      // 2 pages
      list.add(i == _currentPage ? _indicator(true) : _indicator(false));
    }
    return list;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 16.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  // Helper methods copied from HomeScreen (can be made static or moved to utils if needed)
  Widget _buildNutritionInfo(String label, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMealTypeInfo(
      BuildContext context, String label, int count, IconData icon, int limit) {
    Color textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    FontWeight fontWeight = FontWeight.normal;
    Color? iconColor = Theme.of(context).iconTheme.color;

    if (limit > 0) {
      final difference = count - limit;
      if (difference == 1) {
        // Exceeded by 1 -> Yellow
        textColor = Colors.yellow.shade800;
        iconColor = Colors.yellow.shade800;
        fontWeight = FontWeight.bold;
      } else if (difference >= 2) {
        // Exceeded by 2+ -> Red
        textColor = Colors.red.shade700;
        iconColor = Colors.red.shade700;
        fontWeight = FontWeight.bold;
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: iconColor),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.7),
            fontWeight: fontWeight,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.summary == null) {
      // If no summary, show a simpler card
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No entries for today')),
        ),
      );
    }

    // Fixed height for the PageView content area
    const double pageViewHeight = 130.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 16.0), // Padding for top/bottom of card
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: pageViewHeight,
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildMealDistributionPage(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildNutritionPage(context, widget.summary!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12), // Space between PageView and indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildPageIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
