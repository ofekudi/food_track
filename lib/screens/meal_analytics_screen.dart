import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';

class MealAnalyticsScreen extends StatefulWidget {
  const MealAnalyticsScreen({super.key});

  @override
  State<MealAnalyticsScreen> createState() => _MealAnalyticsScreenState();
}

class _MealAnalyticsScreenState extends State<MealAnalyticsScreen> {
  final DBHelper _dbHelper = DBHelper();
  int _daysToShow = 7;
  bool _isLoading = true;

  // Analytics data
  Map<String, int> _reasonCounts = {};
  double _averageHunger = 0;
  Map<int, int> _hourlyDistribution = {};
  Map<int, int> _weekdayDistribution = {};
  Map<int, int> _hungerDistribution = {};
  int _totalEntries = 0;
  int _lowMindfulCount = 0;
  int _lateNightCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: _daysToShow - 1));
    final endDate = now;

    try {
      final results = await Future.wait([
        _dbHelper.getReasonCounts(startDate, endDate),
        _dbHelper.getAverageHungerLevel(startDate, endDate),
        _dbHelper.getHourlyDistribution(startDate, endDate),
        _dbHelper.getWeekdayDistribution(startDate, endDate),
        _dbHelper.getHungerLevelDistribution(startDate, endDate),
        _dbHelper.getEntryCount(startDate, endDate),
        _dbHelper.getLowMindfulEatingCount(startDate, endDate),
        _dbHelper.getLateNightEatingCount(startDate, endDate),
      ]);

      if (mounted) {
        setState(() {
          _reasonCounts = results[0] as Map<String, int>;
          _averageHunger = results[1] as double;
          _hourlyDistribution = results[2] as Map<int, int>;
          _weekdayDistribution = results[3] as Map<int, int>;
          _hungerDistribution = results[4] as Map<int, int>;
          _totalEntries = results[5] as int;
          _lowMindfulCount = results[6] as int;
          _lateNightCount = results[7] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          PopupMenuButton<int>(
            tooltip: 'Time range',
            onSelected: (int value) {
              setState(() {
                _daysToShow = value;
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 14, child: Text('Last 14 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _totalEntries == 0
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 24),
                      _buildReasonPatternsSection(),
                      const SizedBox(height: 24),
                      _buildHungerPatternsSection(),
                      const SizedBox(height: 24),
                      _buildTimePatternsSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No data for this period',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging your meals to see insights',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Entries',
            '$_totalEntries',
            Icons.restaurant_menu,
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Avg Hunger',
            _averageHunger.toStringAsFixed(1),
            Icons.show_chart,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Late Night',
            '$_lateNightCount',
            Icons.nightlight,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonPatternsSection() {
    final total = _reasonCounts.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart),
                const SizedBox(width: 8),
                Text(
                  'Why You Eat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildReasonPieSections(total),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildReasonLegend(total),
            if (_lowMindfulCount > 0) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You ate when not hungry $_lowMindfulCount times this week',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildReasonPieSections(int total) {
    final colors = {
      'hungry': Colors.green,
      'bored': Colors.orange,
      'craving': Colors.pink,
      'social': Colors.blue,
    };

    return _reasonCounts.entries.where((e) => e.value > 0).map((entry) {
      final percentage = (entry.value / total * 100).round();
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '$percentage%',
        color: colors[entry.key] ?? Colors.grey,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildReasonLegend(int total) {
    final labels = {
      'hungry': 'Hungry',
      'bored': 'Bored',
      'craving': 'Craving',
      'social': 'Social',
    };
    final colors = {
      'hungry': Colors.green,
      'bored': Colors.orange,
      'craving': Colors.pink,
      'social': Colors.blue,
    };

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _reasonCounts.entries.map((entry) {
        final count = entry.value;
        final percentage = total > 0 ? (count / total * 100).round() : 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[entry.key],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${labels[entry.key]}: $count ($percentage%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildHungerPatternsSection() {
    final total = _hungerDistribution.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return const SizedBox.shrink();

    final lowHungerCount = (_hungerDistribution[1] ?? 0) + (_hungerDistribution[2] ?? 0);
    final lowHungerPercent = (lowHungerCount / total * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart),
                const SizedBox(width: 8),
                Text(
                  'Hunger Patterns',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _hungerDistribution.values.fold<int>(0, (max, v) => v > max ? v : max).toDouble() + 2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(5, (index) {
                    final level = index + 1;
                    final count = _hungerDistribution[level] ?? 0;
                    return BarChartGroupData(
                      x: level,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: _getHungerColor(level),
                          width: 32,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Hunger level 1 (not hungry) to 5 (very hungry)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  lowHungerPercent > 30 ? Icons.warning_amber : Icons.check_circle,
                  color: lowHungerPercent > 30 ? Colors.orange : Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$lowHungerPercent% of eating happened at low hunger (1-2)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getHungerColor(int level) {
    switch (level) {
      case 1:
        return Colors.red.shade300;
      case 2:
        return Colors.orange.shade300;
      case 3:
        return Colors.yellow.shade600;
      case 4:
        return Colors.lightGreen.shade400;
      case 5:
        return Colors.green.shade500;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTimePatternsSection() {
    // Find peak hours
    final sortedHours = _hourlyDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakHours = sortedHours.take(3).where((e) => e.value > 0).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 8),
                Text(
                  'When You Eat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (peakHours.isNotEmpty) ...[
              Text(
                'Peak eating times:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: peakHours.map((entry) {
                  final hour = entry.key;
                  final timeStr = DateFormat.j().format(DateTime(2024, 1, 1, hour));
                  return Chip(
                    label: Text('$timeStr (${entry.value}x)'),
                    avatar: const Icon(Icons.access_time, size: 16),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            _buildWeekdayChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayChart() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxValue = _weekdayDistribution.values.fold<int>(0, (max, v) => v > max ? v : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'By day of week:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final day = index + 1; // 1=Monday, 7=Sunday
            final count = _weekdayDistribution[day] ?? 0;
            final height = maxValue > 0 ? (count / maxValue * 40) : 0.0;

            return Column(
              children: [
                Container(
                  width: 32,
                  height: 40,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 24,
                    height: height,
                    decoration: BoxDecoration(
                      color: (day == 6 || day == 7)
                          ? Theme.of(context).colorScheme.tertiary
                          : Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weekdays[index],
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
