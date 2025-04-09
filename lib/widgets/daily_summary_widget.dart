import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_provider.dart';

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
                'Breakfast',
                mealTypeCounts['Breakfast'] ?? 0,
                Icons.breakfast_dining,
              ),
              _buildMealTypeInfo(
                'Lunch',
                mealTypeCounts['Lunch'] ?? 0,
                Icons.lunch_dining,
              ),
              _buildMealTypeInfo(
                'Dinner',
                mealTypeCounts['Dinner'] ?? 0,
                Icons.dinner_dining,
              ),
              _buildMealTypeInfo(
                'Snack',
                mealTypeCounts['Snack'] ?? 0,
                Icons.cookie,
              ),
              _buildMealTypeInfo(
                'Coffee',
                mealTypeCounts['Coffee'] ?? 0,
                Icons.coffee,
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

  Widget _buildMealTypeInfo(String label, int count, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
