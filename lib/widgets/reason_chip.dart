import 'package:flutter/material.dart';
import '../models/eating_log.dart';
import '../constants/theme.dart';

/// Chip widget for displaying or selecting an eating reason
class ReasonChip extends StatelessWidget {
  final EatingReason reason;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool compact;

  const ReasonChip({
    super.key,
    required this.reason,
    this.isSelected = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AppTheme.reasonIcon(reason.name);

    if (compact) {
      return Chip(
        avatar: Icon(icon, size: 16),
        label: Text(reason.displayName, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
      );
    }

    return ActionChip(
      avatar: Icon(
        icon,
        size: 20,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        reason.displayName,
        style: TextStyle(
          fontSize: 16,
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

/// Row displaying reason with icon (for list items)
class ReasonLabel extends StatelessWidget {
  final EatingReason reason;

  const ReasonLabel({
    super.key,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final icon = AppTheme.reasonIcon(reason.name);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          reason.displayName,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
