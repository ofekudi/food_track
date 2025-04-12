import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../providers/settings_provider.dart'; // Import SettingsProvider
import 'daily_limit_screen.dart';
import 'stop_eating_settings_screen.dart'; // Import the new screen
import 'manage_favorites_screen.dart'; // Import the favorites screen

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  // Time picker helper removed as it's moving to the new screen

  @override
  Widget build(BuildContext context) {
    // Consumer is no longer strictly needed here, but can remain
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        // We don't need the time formatting here anymore

        return Scaffold(
          appBar: AppBar(
            title: const Text('Preferences'),
          ),
          body: ListView(
            children: [
              ListTile(
                title: const Text('Daily Meal Limits'),
                subtitle: const Text('Set limits for each meal type'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DailyLimitScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Manage Favorites'),
                subtitle:
                    const Text('Add, edit, or remove favorite food items'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageFavoritesScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Stop Eating Time'), // Updated title
                subtitle: const Text(
                    'Configure end-of-day notification'), // Generic subtitle
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to the new settings screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StopEatingSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
