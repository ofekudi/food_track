import 'package:flutter/material.dart';

/// App-wide theme constants
class AppTheme {
  // Hunger indicator color (for list items)
  static Color hungerIndicatorColor(int level) {
    if (level <= 2) {
      return Colors.orange;
    } else if (level >= 4) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  // Reason icons
  static IconData reasonIcon(String reason) {
    switch (reason) {
      case 'hungry':
        return Icons.restaurant;
      case 'bored':
        return Icons.mood_bad;
      case 'craving':
        return Icons.favorite;
      case 'social':
        return Icons.people;
      case 'habit':
        return Icons.repeat;
      case 'drink':
        return Icons.local_cafe;
      default:
        return Icons.help_outline;
    }
  }
}
