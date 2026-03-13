import 'package:flutter/material.dart';
import '../constants/theme.dart';

/// Circular indicator showing hunger level (1-5)
class HungerIndicator extends StatelessWidget {
  final int level;
  final double size;

  const HungerIndicator({
    super.key,
    required this.level,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.hungerIndicatorColor(level);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          '$level',
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Tappable hunger level button for selection
class HungerButton extends StatelessWidget {
  final int level;
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const HungerButton({
    super.key,
    required this.level,
    required this.isSelected,
    required this.onTap,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$level',
            style: TextStyle(
              fontSize: size * 0.43,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
