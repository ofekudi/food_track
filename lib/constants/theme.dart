import 'package:flutter/material.dart';

/// App-wide theme constants
class AppTheme {
  // Hunger level colors
  static Color hungerColor(int level) {
    switch (level) {
      case 1:
        return Colors.red.shade300;
      case 2:
        return Colors.orange.shade300;
      case 3:
        return Colors.yellow.shade600;
      case 4:
        return Colors.lightGreen.shade400;
      case 5:
        return Colors.green.shade500;
      default:
        return Colors.grey;
    }
  }

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

  // Reason colors for pie chart
  static const reasonColors = {
    'hungry': Colors.green,
    'bored': Colors.orange,
    'craving': Colors.pink,
    'social': Colors.blue,
    'habit': Colors.teal,
  };

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
      default:
        return Icons.help_outline;
    }
  }
}
