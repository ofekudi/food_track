import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db_helper.dart';
import '../constants/strings.dart';
import '../constants/theme.dart';

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
          _hungerDistribution = results[3] as Map<int, int>;
          _totalEntries = results[4] as int;
          _lowMindfulCount = results[5] as int;
          _lateNightCount = results[6] as int;
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

  String get _periodLabel {
    switch (_daysToShow) {
      case 7:
        return 'Last 7 days';
      case 14:
        return 'Last 14 days';
      case 30:
        return 'Last 30 days';
      default:
        return 'Last $_daysToShow days';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.weeklyInsights),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Time range',
            onSelected: (int value) {
              setState(() {
                _daysToShow = value;
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text(AppStrings.last7Days)),
              const PopupMenuItem(value: 14, child: Text(AppStrings.last14Days)),
              const PopupMenuItem(value: 30, child: Text(AppStrings.last30Days)),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _totalEntries == 0
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildPeriodHeader(),
                      const SizedBox(height: 20),
                      _buildKeyStats(),
                      const SizedBox(height: 24),
                      _buildReasonBreakdown(),
                      const SizedBox(height: 24),
                      _buildHungerInsight(),
                      const SizedBox(height: 24),
                      _buildTimeInsight(),
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
            AppStrings.noDataTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.noDataSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    return Text(
      _periodLabel,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Widget _buildKeyStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: '$_totalEntries',
            label: 'entries',
            icon: Icons.restaurant,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: _averageHunger.toStringAsFixed(1),
            label: 'avg hunger',
            icon: Icons.speed,
            color: _averageHunger >= 3 ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: '$_lateNightCount',
            label: 'after 9pm',
            icon: Icons.nightlight_round,
            color: _lateNightCount > 0 ? Colors.purple : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonBreakdown() {
    final total = _reasonCounts.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return const SizedBox.shrink();

    final sortedReasons = _reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why you ate',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...sortedReasons.where((e) => e.value > 0).map((entry) {
          final percentage = (entry.value / total * 100).round();
          final color = AppTheme.reasonColors[entry.key] ?? Colors.grey;
          final icon = AppTheme.reasonIcon(entry.key);
          final label = _reasonLabel(entry.key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
        if (_lowMindfulCount > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$_lowMindfulCount times you ate when not hungry',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'hungry':
        return 'Hungry';
      case 'bored':
        return 'Bored';
      case 'craving':
        return 'Craving';
      case 'social':
        return 'Social';
      default:
        return reason;
    }
  }

  Widget _buildHungerInsight() {
    final total = _hungerDistribution.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return const SizedBox.shrink();

    final highHungerCount = (_hungerDistribution[4] ?? 0) + (_hungerDistribution[5] ?? 0);
    final highHungerPercent = (highHungerCount / total * 100).round();
    final isGood = highHungerPercent >= 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hunger levels',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (isGood ? Colors.green : Colors.orange).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isGood ? Icons.check_circle : Icons.info_outline,
                color: isGood ? Colors.green : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$highHungerPercent% mindful eating',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isGood
                          ? 'You mostly eat when actually hungry'
                          : 'You often eat when not very hungry',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final level = index + 1;
            final count = _hungerDistribution[level] ?? 0;
            final maxCount = _hungerDistribution.values.fold<int>(0, (max, v) => v > max ? v : max);
            final heightPercent = maxCount > 0 ? count / maxCount : 0.0;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        height: 60 * heightPercent,
                        decoration: BoxDecoration(
                          color: AppTheme.hungerColor(level),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$level',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Not hungry',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              'Very hungry',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeInsight() {
    // Find peak hours
    final sortedHours = _hourlyDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakHours = sortedHours.take(3).where((e) => e.value > 0).toList();

    if (peakHours.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peak eating times',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: peakHours.map((entry) {
            final hour = entry.key;
            final timeStr = DateFormat.j().format(DateTime(2024, 1, 1, hour));
            final isLateNight = hour >= 21 || hour < 5;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isLateNight
                    ? Colors.purple.withOpacity(0.1)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLateNight ? Icons.nightlight_round : Icons.access_time,
                    size: 18,
                    color: isLateNight ? Colors.purple : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${entry.value}x)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
