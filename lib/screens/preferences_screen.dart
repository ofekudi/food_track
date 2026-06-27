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
      builder: (_) => _PauseDurationDialog(initialSeconds: settings.pauseSeconds),
    );
    if (result != null) {
      await settings.setPauseSeconds(result);
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
        ],
      ),
    );
  }
}

/// Lets the user pick the mindful pause duration (0–[maxPauseSeconds] seconds).
class _PauseDurationDialog extends StatefulWidget {
  final int initialSeconds;

  const _PauseDurationDialog({required this.initialSeconds});

  @override
  State<_PauseDurationDialog> createState() => _PauseDurationDialogState();
}

class _PauseDurationDialogState extends State<_PauseDurationDialog> {
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.pauseTimerDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _seconds <= 0 ? AppStrings.off : '$_seconds ${AppStrings.seconds}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Slider(
            value: _seconds.toDouble(),
            min: 0,
            max: SettingsProvider.maxPauseSeconds.toDouble(),
            divisions: SettingsProvider.maxPauseSeconds,
            label: _seconds <= 0 ? AppStrings.off : '${_seconds}s',
            onChanged: (value) => setState(() => _seconds = value.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_seconds),
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
