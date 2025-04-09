import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/food_provider.dart';
import '../models/food_entry.dart';

class MealAnalyticsScreen extends StatefulWidget {
  const MealAnalyticsScreen({super.key});

  @override
  State<MealAnalyticsScreen> createState() => _MealAnalyticsScreenState();
}

class _MealAnalyticsScreenState extends State<MealAnalyticsScreen> {
  int _daysToShow = 7; // Default to show 7 days
  Map<String, List<FoodEntry>> _mealTypeData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
    });

    // Give some time for data to load
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _mealTypeData = _generateMealTypeData(
              Provider.of<FoodProvider>(context, listen: false), _daysToShow);
          _isLoading = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh data',
            onPressed: _loadData,
          ),
          PopupMenuButton<int>(
            tooltip: 'Select time range',
            onSelected: (int value) {
              setState(() {
                _daysToShow = value;
                _loadData();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 7,
                child: Text('Last 7 days'),
              ),
              const PopupMenuItem(
                value: 14,
                child: Text('Last 14 days'),
              ),
              const PopupMenuItem(
                value: 30,
                child: Text('Last 30 days'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_mealTypeData.isEmpty)
                    const Center(
                      heightFactor: 3,
                      child: Text(
                        'No data available for the selected period',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  else
                    ..._buildMealTypeStatistics(),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildMealTypeStatistics() {
    final List<Widget> widgets = [];
    final List<String> mealTypes = [
      'Coffee',
      'Snack',
      'Breakfast',
      'Lunch',
      'Dinner',
    ];

    final mealTypeIcons = {
      'Breakfast': Icons.breakfast_dining,
      'Lunch': Icons.lunch_dining,
      'Dinner': Icons.dinner_dining,
      'Snack': Icons.cookie,
      'Coffee': Icons.coffee,
    };

    for (final mealType in mealTypes) {
      final entries = _mealTypeData[mealType] ?? [];

      if (entries.isNotEmpty) {
        final stats = _calculateStats(entries, mealType);
        final icon = mealTypeIcons[mealType] ?? Icons.restaurant;
        final borderColor = _getMealTypeColor(mealType);
        final cardColor = _getMealTypeColor(mealType).withOpacity(0.7);

        widgets.add(
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 1),
            ),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 32, color: borderColor),
                      const SizedBox(width: 8),
                      Text(
                        mealType,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: borderColor,
                        ),
                      ),
                    ],
                  ),
                  const Divider(thickness: 1, color: Colors.white30),
                  const SizedBox(height: 8),
                  _buildStatRow('Total Count', '${stats['count']}'),
                  _buildStatRow('AVG Per Day', stats['averagePerDay']),
                  _buildStatRow('Daily AVG (30d)', stats['avgLast30Days']),
                  _buildStatRow('Daily AVG (365d)', stats['avgLast365Days']),
                  _buildStatRow('Most Popular', stats['mostPopular']),
                ],
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateStats(
      List<FoodEntry> entries, String mealType) {
    final stats = <String, dynamic>{};

    // Total count
    stats['count'] = entries.length;

    // Average per day - only count days that have entries
    final Set<String> uniqueDates = entries
        .map((entry) => DateFormat('yyyy-MM-dd').format(entry.entryDate))
        .toSet();

    final int daysWithData = uniqueDates.length;
    stats['averagePerDay'] = (daysWithData > 0)
        ? (entries.length / daysWithData).toStringAsFixed(1)
        : '0';

    // Daily average (30d) - only count days with data
    final now30d = DateTime.now().subtract(const Duration(days: 30));
    final entries30d = entries
        .where((entry) =>
            entry.entryDate.isAfter(now30d) ||
            entry.entryDate.isAtSameMomentAs(now30d))
        .toList();

    final Set<String> uniqueDates30d = entries30d
        .map((entry) => DateFormat('yyyy-MM-dd').format(entry.entryDate))
        .toSet();

    final int daysWithData30d = uniqueDates30d.length;
    stats['avgLast30Days'] = (daysWithData30d > 0)
        ? (entries30d.length / daysWithData30d).toStringAsFixed(1)
        : '0';

    // Daily average (365d) - only count days with data
    final now365d = DateTime.now().subtract(const Duration(days: 365));
    final entries365d = entries
        .where((entry) =>
            entry.entryDate.isAfter(now365d) ||
            entry.entryDate.isAtSameMomentAs(now365d))
        .toList();

    final Set<String> uniqueDates365d = entries365d
        .map((entry) => DateFormat('yyyy-MM-dd').format(entry.entryDate))
        .toSet();

    final int daysWithData365d = uniqueDates365d.length;
    stats['avgLast365Days'] = (daysWithData365d > 0)
        ? (entries365d.length / daysWithData365d).toStringAsFixed(2)
        : '0';

    // Most popular food
    final Map<String, int> foodCounts = {};
    for (final entry in entries) {
      foodCounts[entry.name] = (foodCounts[entry.name] ?? 0) + 1;
    }

    String mostPopular = 'None';
    int maxCount = 0;
    foodCounts.forEach((food, count) {
      if (count > maxCount) {
        mostPopular = food;
        maxCount = count;
      }
    });

    // Truncate long food names
    if (mostPopular.length > 15) {
      mostPopular = '${mostPopular.substring(0, 12)}...';
    }

    stats['mostPopular'] = mostPopular;

    return stats;
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'Breakfast':
        return Colors.orange;
      case 'Lunch':
        return Colors.blue;
      case 'Dinner':
        return Colors.purple;
      case 'Snack':
        return Colors.green;
      case 'Coffee':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Map<String, List<FoodEntry>> _generateMealTypeData(
      FoodProvider provider, int days) {
    // Get entries stored in memory
    final allEntries = provider.getAllFoodEntries();
    if (allEntries.isEmpty) return {};

    // Filter for entries within the date range
    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    // Group by meal type
    final Map<String, List<FoodEntry>> mealTypeData = {};

    for (final entry in allEntries) {
      if (entry.entryDate.compareTo(startDate) >= 0 &&
          entry.entryDate.compareTo(now) <= 0) {
        mealTypeData[entry.mealType] ??= [];
        mealTypeData[entry.mealType]!.add(entry);
      }
    }

    return mealTypeData;
  }
}
