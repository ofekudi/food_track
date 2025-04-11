import 'package:flutter/material.dart';
import 'daily_limit_screen.dart'; // We'll create this next

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded), // Icon for limits
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
          // Add other preferences here in the future
        ],
      ),
    );
  }
}
