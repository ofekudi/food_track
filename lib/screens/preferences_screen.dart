import 'package:flutter/material.dart';
import '../constants/strings.dart';
import 'stop_eating_settings_screen.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

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
        ],
      ),
    );
  }
}
