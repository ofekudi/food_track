import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/strings.dart';
import '../providers/settings_provider.dart';
import 'stop_eating_settings_screen.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  String _pauseLabel(int seconds) =>
      seconds <= 0 ? AppStrings.off : '${seconds}s';

  Future<void> _editPauseSeconds(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _SliderPickerDialog(
        title: AppStrings.pauseTimerDialogTitle,
        initialValue: settings.pauseSeconds,
        min: 0,
        max: SettingsProvider.maxPauseSeconds,
        valueLabel: (value) =>
            value <= 0 ? AppStrings.off : '$value ${AppStrings.seconds}',
        sliderLabel: _pauseLabel,
      ),
    );
    if (result != null) {
      await settings.setPauseSeconds(result);
    }
  }

  Future<void> _editRecordingsTarget(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _SliderPickerDialog(
        title: AppStrings.recordingsTargetDialogTitle,
        initialValue: settings.recordingsTarget,
        min: SettingsProvider.minRecordingsTarget,
        max: SettingsProvider.maxRecordingsTarget,
        valueLabel: (value) => '$value ${AppStrings.recordingsPerDayUnit}',
        sliderLabel: (value) => '$value',
      ),
    );
    if (result != null) {
      await settings.setRecordingsTarget(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.preferences),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bedtime_outlined),
            title: const Text(AppStrings.kitchenClosed),
            subtitle: const Text(AppStrings.kitchenClosedSubtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StopEatingSettingsScreen(),
                ),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text(AppStrings.pauseTimer),
              subtitle: const Text(AppStrings.pauseTimerSubtitle),
              trailing: Text(
                _pauseLabel(settings.pauseSeconds),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              onTap: () => _editPauseSeconds(context),
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text(AppStrings.dailyRecordingsTarget),
              subtitle: const Text(AppStrings.dailyRecordingsTargetSubtitle),
              trailing: Text(
                '${settings.recordingsTarget}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              onTap: () => _editRecordingsTarget(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets the user pick a whole number in [min]–[max] with a slider.
class _SliderPickerDialog extends StatefulWidget {
  final String title;
  final int initialValue;
  final int min;
  final int max;

  /// Big headline above the slider, e.g. "5 seconds".
  final String Function(int value) valueLabel;

  /// Compact bubble label on the slider thumb, e.g. "5s".
  final String Function(int value) sliderLabel;

  const _SliderPickerDialog({
    required this.title,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.sliderLabel,
  });

  @override
  State<_SliderPickerDialog> createState() => _SliderPickerDialogState();
}

class _SliderPickerDialogState extends State<_SliderPickerDialog> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.valueLabel(_value),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Slider(
            value: _value.toDouble(),
            min: widget.min.toDouble(),
            max: widget.max.toDouble(),
            divisions: widget.max - widget.min,
            label: widget.sliderLabel(_value),
            onChanged: (value) => setState(() => _value = value.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value),
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
