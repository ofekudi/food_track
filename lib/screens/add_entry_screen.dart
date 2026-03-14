import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/eating_provider.dart';
import '../models/eating_log.dart';
import '../constants/strings.dart';
import '../constants/theme.dart';
import '../widgets/hunger_indicator.dart';
import '../widgets/reason_chip.dart';
import '../widgets/suggestion_tile.dart';

class AddEntryScreen extends StatefulWidget {
  final DateTime targetDate;
  final EatingLog? entryToEdit;

  const AddEntryScreen({
    super.key,
    required this.targetDate,
    this.entryToEdit,
  });

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  int _currentStep = 0;
  int? _selectedHunger;
  EatingReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _showIntervention = false;

  bool get _isEditing => widget.entryToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final entry = widget.entryToEdit!;
      _selectedHunger = entry.hungerLevel;
      _selectedReason = entry.reason;
      _descriptionController.text = entry.description;
      _currentStep = 2;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onHungerSelected(int level) {
    setState(() {
      _selectedHunger = level;
      _currentStep = 1;
    });
  }

  void _onReasonSelected(EatingReason reason) {
    setState(() {
      _selectedReason = reason;
      if (_selectedHunger != null && _selectedHunger! <= 2 && reason == EatingReason.bored) {
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
    final description = _descriptionController.text.trim();
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
                  onPressed: _descriptionController.text.trim().isNotEmpty
                      ? _submitEntry
                      : null,
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
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: AppStrings.descriptionPlaceholder,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            autofocus: true,
            onChanged: (_) => setState(() {}),
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
