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
  // Helper function to show time picker
  Future<void> _selectStopTime(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    // Use the stored time if available, otherwise default (e.g., 10 PM)
    final initialTime = settingsProvider.kitchenClosedTime ??
        const TimeOfDay(hour: 22, minute: 0);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Select Stop Eating Time',
    );

    if (pickedTime != null) {
      // Only set time, don't enable/disable here
      await settingsProvider.setKitchenClosedTime(pickedTime);
    }
  }

  // --- New Helper to show Title Selection Dialog ---
  Future<void> _showTitleSelectionDialog(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    String? currentSelection = settingsProvider.stopEatingTitle;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use StatefulBuilder to manage the dropdown state within the dialog
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Notification Title'),
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
                    Navigator.of(dialogContext).pop(); // Close without saving
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    if (currentSelection != null) {
                      settingsProvider.setStopEatingTitle(currentSelection!);
                    }
                    Navigator.of(dialogContext).pop(); // Close after saving
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  // --- End of New Helper ---

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        final isEnabled = settings.stopEatingEnabled;
        final selectedTime =
            settings.kitchenClosedTime; // Getter handles enabled state
        final selectedTitle = settings.stopEatingTitle;
        final formattedTime =
            selectedTime != null ? selectedTime.format(context) : 'Not set';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Stop Eating Settings'),
          ),
          body: ListView(
            children: [
              SwitchListTile(
                title: const Text('Enabled'),
                value: isEnabled,
                onChanged: (bool value) async {
                  await settings.setStopEatingEnabled(value);
                  // Optionally, prompt to set time if enabling and no time is set
                  if (value && settings.kitchenClosedTime == null) {
                    _selectStopTime(context);
                  }
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Stop Eating Time'),
                subtitle: Text(formattedTime),
                enabled: isEnabled, // Disable if feature is off
                onTap: isEnabled ? () => _selectStopTime(context) : null,
              ),
              const Divider(),
              ListTile(
                title: const Text('Title'),
                subtitle: Text(selectedTitle),
                enabled: isEnabled, // Disable if feature is off
                onTap: isEnabled
                    ? () => _showTitleSelectionDialog(
                        context) // Call the dialog helper
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
