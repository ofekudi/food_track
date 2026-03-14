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
  Map<int, Map<String, int>> _hourlyByReason = {};
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
        _dbHelper.getHourlyDistributionByReason(startDate, endDate),
        _dbHelper.getHungerLevelDistribution(startDate, endDate),
        _dbHelper.getEntryCount(startDate, endDate),
        _dbHelper.getLowMindfulEatingCount(startDate, endDate),
        _dbHelper.getLateNightEatingCount(startDate, endDate),
      ]);

      if (mounted) {
        setState(() {
          _reasonCounts = results[0] as Map<String, int>;
          _averageHunger = results[1] as double;
          _hourlyByReason = results[2] as Map<int, Map<String, int>>;
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

    final maxCount = _hungerDistribution.values.fold<int>(0, (max, v) => v > max ? v : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.hungerLevels,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (index) {
              final level = index + 1;
              final count = _hungerDistribution[level] ?? 0;
              final heightPercent = maxCount > 0 ? count / maxCount : 0.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Tooltip(
                    message: 'Hunger $level: $count entries',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (count > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '$count',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        Container(
                          width: double.infinity,
                          height: 80 * heightPercent + (count > 0 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: AppTheme.hungerColor(level),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final level = index + 1;
            return Expanded(
              child: Text(
                '$level',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.notHungry,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              AppStrings.veryHungry,
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
    // Calculate max total count for any hour
    int maxCount = 0;
    for (int hour = 6; hour <= 23; hour++) {
      final hourData = _hourlyByReason[hour] ?? {};
      final total = hourData.values.fold<int>(0, (sum, v) => sum + v);
      if (total > maxCount) maxCount = total;
    }
    if (maxCount == 0) return const SizedBox.shrink();

    const startHour = 6;
    const endHour = 23;
    const reasons = ['hungry', 'bored', 'craving', 'social'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.eatingTimes,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(endHour - startHour + 1, (index) {
              final hour = startHour + index;
              final hourData = _hourlyByReason[hour] ?? {};
              final total = hourData.values.fold<int>(0, (sum, v) => sum + v);
              final totalHeight = maxCount > 0 ? (80 * total / maxCount) + (total > 0 ? 4 : 0) : 0.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Tooltip(
                    message: _buildHourTooltip(hour, hourData),
                    child: SizedBox(
                      height: totalHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: reasons.reversed.map((reason) {
                          final count = hourData[reason] ?? 0;
                          if (count == 0) return const SizedBox.shrink();
                          final segmentHeight = totalHeight * (count / total);
                          return Container(
                            width: double.infinity,
                            height: segmentHeight,
                            color: AppTheme.reasonColors[reason],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '6am',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              '12pm',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              '6pm',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              '11pm',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: reasons.map((reason) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.reasonColors[reason],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _reasonLabel(reason),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  String _buildHourTooltip(int hour, Map<String, int> hourData) {
    final timeStr = DateFormat.j().format(DateTime(2024, 1, 1, hour));
    final total = hourData.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return '$timeStr: no entries';

    final parts = <String>[];
    for (final reason in ['hungry', 'bored', 'craving', 'social']) {
      final count = hourData[reason] ?? 0;
      if (count > 0) {
        parts.add('${_reasonLabel(reason)}: $count');
      }
    }
    return '$timeStr ($total)\n${parts.join(', ')}';
  }
}
