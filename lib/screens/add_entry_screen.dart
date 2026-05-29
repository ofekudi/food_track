import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/eating_provider.dart';
import '../models/eating_log.dart';
import '../constants/strings.dart';
import '../constants/theme.dart';
import '../widgets/hunger_indicator.dart';
import '../widgets/reason_chip.dart';
import '../widgets/suggestion_tile.dart';

/// Holds the two controllers for a single food item row (amount + food).
class _ItemRow {
  final TextEditingController amount = TextEditingController();
  final TextEditingController food = TextEditingController();

  void dispose() {
    amount.dispose();
    food.dispose();
  }
}

class AddEntryScreen extends StatefulWidget {
  final DateTime targetDate;
  final EatingLog? entryToEdit;
  final EatingReason? preselectedReason;

  const AddEntryScreen({
    super.key,
    required this.targetDate,
    this.entryToEdit,
    this.preselectedReason,
  });

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  int _currentStep = 0;
  int? _selectedHunger;
  EatingReason? _selectedReason;
  final List<_ItemRow> _itemRows = [];
  bool _showIntervention = false;

  bool get _isEditing => widget.entryToEdit != null;

  /// True once at least one row has a non-empty food, so the entry can be saved.
  bool get _hasValidItems =>
      _itemRows.any((r) => r.food.text.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final entry = widget.entryToEdit!;
      _selectedHunger = entry.hungerLevel;
      _selectedReason = entry.reason;
      _seedRowsFromDescription(entry.description);
      _currentStep = 2;
    } else {
      if (widget.preselectedReason != null) {
        _selectedReason = widget.preselectedReason;
      }
      _itemRows.add(_ItemRow());
    }
  }

  /// Splits a stored comma-joined description back into rows (one per segment,
  /// kept whole in the food field). Always leaves at least one row.
  void _seedRowsFromDescription(String description) {
    final segments = description
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      _itemRows.add(_ItemRow());
      return;
    }
    for (final segment in segments) {
      final row = _ItemRow();
      row.food.text = segment;
      _itemRows.add(row);
    }
  }

  @override
  void dispose() {
    for (final row in _itemRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() => _itemRows.add(_ItemRow()));
  }

  void _removeRow(int index) {
    setState(() {
      _itemRows[index].dispose();
      _itemRows.removeAt(index);
    });
  }

  /// Builds the comma-joined summary stored in `description` from the rows.
  /// Rows with an empty food are dropped; amount + food are joined with a space.
  String _composeDescription() {
    return _itemRows
        .map((r) {
          final amount = r.amount.text.trim();
          final food = r.food.text.trim();
          if (food.isEmpty) return '';
          return amount.isEmpty ? food : '$amount $food';
        })
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  void _onHungerSelected(int level) {
    setState(() {
      _selectedHunger = level;
      if (_selectedReason != null) {
        final shouldIntervene =
            level <= 2 &&
            (_selectedReason == EatingReason.bored ||
                _selectedReason == EatingReason.craving);
        if (shouldIntervene) {
          _showIntervention = true;
        } else {
          _currentStep = 2;
        }
      } else {
        _currentStep = 1;
      }
    });
  }

  void _onReasonSelected(EatingReason reason) {
    setState(() {
      _selectedReason = reason;
      final shouldIntervene = _selectedHunger != null &&
          _selectedHunger! <= 2 &&
          (reason == EatingReason.bored || reason == EatingReason.craving);
      if (shouldIntervene) {
        _showIntervention = true;
      } else {
        _currentStep = 2;
      }
    });
  }

  void _onProceedAnyway() {
    setState(() {
      _showIntervention = false;
      _currentStep = 2;
    });
  }

  void _onDismissIntervention() {
    Navigator.pop(context);
  }

  Future<void> _submitEntry() async {
    final description = _composeDescription();
    if (description.isEmpty || _selectedHunger == null || _selectedReason == null) {
      return;
    }

    final eatingProvider = context.read<EatingProvider>();

    if (_isEditing) {
      final updatedLog = EatingLog(
        id: widget.entryToEdit!.id,
        description: description,
        hungerLevel: _selectedHunger!,
        reason: _selectedReason!,
        entryDate: widget.entryToEdit!.entryDate,
        createdAt: widget.entryToEdit!.createdAt,
      );
      await eatingProvider.updateEatingLog(updatedLog);
    } else {
      await eatingProvider.addEatingLog(
        description: description,
        hungerLevel: _selectedHunger!,
        reason: _selectedReason!,
        entryDate: widget.targetDate,
      );
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDescriptionStep = _currentStep == 2 && !_showIntervention;

    return Scaffold(
      appBar: AppBar(
        actions: isDescriptionStep
            ? [
                TextButton(
                  onPressed: _hasValidItems ? _submitEntry : null,
                  child: Text(_isEditing ? AppStrings.save : AppStrings.done),
                ),
              ]
            : null,
      ),
      body: _showIntervention
          ? _buildInterventionScreen()
          : _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildHungerStep();
      case 1:
        return _buildReasonStep();
      case 2:
        return _buildDescriptionStep();
      default:
        return _buildHungerStep();
    }
  }

  Widget _buildHungerStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            AppStrings.hungerQuestion,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.hungerHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final level = index + 1;
              return HungerButton(
                level: level,
                isSelected: _selectedHunger == level,
                onTap: () => _onHungerSelected(level),
              );
            }),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.notHungry,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                AppStrings.veryHungry,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            AppStrings.reasonQuestion,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: EatingReason.values.map((reason) {
              return ReasonChip(
                reason: reason,
                isSelected: _selectedReason == reason,
                onTap: () => _onReasonSelected(reason),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterventionScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.interventionTitle,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.interventionSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const SuggestionsList(),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: _onProceedAnyway,
            child: const Text(AppStrings.logAnyway),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _onDismissIntervention,
            child: const Text(AppStrings.maybeLater),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            AppStrings.descriptionQuestion,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.descriptionHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...List.generate(_itemRows.length, (index) {
            final row = _itemRows[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: row.amount,
                      decoration: InputDecoration(
                        hintText: AppStrings.amountPlaceholder,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: row.food,
                      decoration: InputDecoration(
                        hintText: AppStrings.foodPlaceholder,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      autofocus: index == 0,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: _itemRows.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            tooltip: AppStrings.removeItem,
                            onPressed: () => _removeRow(index),
                          )
                        : null,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addRow,
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addItem),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedHunger != null && _selectedReason != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          AppStrings.hunger,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_selectedHunger/5',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    Column(
                      children: [
                        Text(
                          AppStrings.reason,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppTheme.reasonIcon(_selectedReason!.name),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedReason!.displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
