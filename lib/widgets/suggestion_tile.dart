import 'package:flutter/material.dart';
import '../constants/strings.dart';

/// A single suggestion row with icon and text
class SuggestionTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const SuggestionTile({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

/// List of default mindfulness suggestions
class SuggestionsList extends StatelessWidget {
  final bool compact;

  const SuggestionsList({
    super.key,
    this.compact = false,
  });

  static const suggestions = [
    (Icons.water_drop, AppStrings.suggestionWater),
    (Icons.timer, AppStrings.suggestionWait),
    (Icons.directions_walk, AppStrings.suggestionWalk),
    (Icons.air, AppStrings.suggestionBreathe),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: suggestions.map((s) {
        if (compact) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Icon(s.$1, size: 20),
                const SizedBox(width: 12),
                Text(s.$2),
              ],
            ),
          );
        }
        return SuggestionTile(icon: s.$1, text: s.$2);
      }).toList(),
    );
  }
}
