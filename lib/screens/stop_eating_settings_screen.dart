import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class StopEatingSettingsScreen extends StatefulWidget {
  const StopEatingSettingsScreen({super.key});

  @override
  State<StopEatingSettingsScreen> createState() =>
      _StopEatingSettingsScreenState();
}

class _StopEatingSettingsScreenState extends State<StopEatingSettingsScreen> {
  Future<void> _selectStopTime(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    final initialTime = settingsProvider.kitchenClosedTime ??
        const TimeOfDay(hour: 22, minute: 0);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Select Kitchen Closed Time',
    );

    if (pickedTime != null) {
      await settingsProvider.setKitchenClosedTime(pickedTime);
    }
  }

  Future<void> _showTitleSelectionDialog(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    String? currentSelection = settingsProvider.stopEatingTitle;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Reminder Title'),
              content: DropdownButton<String>(
                value: currentSelection,
                isExpanded: true,
                items: settingsProvider.availableStopEatingTitles
                    .map((String title) {
                  return DropdownMenuItem<String>(
                    value: title,
                    child: Text(title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    currentSelection = newValue;
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    if (currentSelection != null) {
                      settingsProvider.setStopEatingTitle(currentSelection!);
                    }
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final isEnabled = settings.stopEatingEnabled;
        final selectedTime = settings.kitchenClosedTime;
        final selectedTitle = settings.stopEatingTitle;
        final formattedTime =
            selectedTime != null ? selectedTime.format(context) : 'Not set';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Kitchen Closed'),
          ),
          body: ListView(
            children: [
              SwitchListTile(
                title: const Text('Enabled'),
                subtitle: const Text('Show reminder after this time'),
                value: isEnabled,
                onChanged: (bool value) async {
                  await settings.setStopEatingEnabled(value);
                  if (value && settings.kitchenClosedTime == null) {
                    if (mounted) {
                      _selectStopTime(context);
                    }
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(formattedTime),
                enabled: isEnabled,
                onTap: isEnabled ? () => _selectStopTime(context) : null,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.title),
                title: const Text('Reminder Title'),
                subtitle: Text(selectedTitle),
                enabled: isEnabled,
                onTap: isEnabled
                    ? () => _showTitleSelectionDialog(context)
                    : null,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'When enabled, a gentle reminder will appear if you open the app after the set time, asking if you\'re truly hungry or just snacking out of habit.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
