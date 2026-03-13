import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/eating_provider.dart';
import '../models/eating_log.dart';

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
      _currentStep = 2; // Go straight to description for editing
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
      // Check if intervention should be shown
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : 'Log Eating'),
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
            'How hungry are you?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Tap a number from 1 (not hungry) to 5 (very hungry)',
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
              final isSelected = _selectedHunger == level;
              return _buildHungerButton(level, isSelected);
            }),
          ),
          const SizedBox(height: 48),
          _buildHungerLabels(),
        ],
      ),
    );
  }

  Widget _buildHungerButton(int level, bool isSelected) {
    return GestureDetector(
      onTap: () => _onHungerSelected(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
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
              fontSize: 24,
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

  Widget _buildHungerLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Not hungry',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          'Very hungry',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
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
            'Why are you eating?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: EatingReason.values.map((reason) {
              return _buildReasonChip(reason);
            }).toList(),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _currentStep = 0;
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to hunger'),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonChip(EatingReason reason) {
    final isSelected = _selectedReason == reason;
    final IconData icon;
    switch (reason) {
      case EatingReason.hungry:
        icon = Icons.restaurant;
        break;
      case EatingReason.bored:
        icon = Icons.mood_bad;
        break;
      case EatingReason.craving:
        icon = Icons.favorite;
        break;
      case EatingReason.social:
        icon = Icons.people;
        break;
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
      onPressed: () => _onReasonSelected(reason),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            'Not very hungry?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "That's okay! Here are some alternatives you might try:",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildSuggestionTile(Icons.water_drop, 'Drink a glass of water'),
          _buildSuggestionTile(Icons.timer, 'Wait 10 minutes'),
          _buildSuggestionTile(Icons.directions_walk, 'Take a short walk'),
          _buildSuggestionTile(Icons.air, 'Take 3 deep breaths'),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: _onProceedAnyway,
            child: const Text('Log anyway'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _onDismissIntervention,
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Text(
            'What are you eating?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Just a simple description is fine',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'e.g., "3 schnitzels" or "handful of chips"',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          // Show current selections
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
                          'Hunger',
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
                          'Reason',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedReason!.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const Spacer(),
          if (!_isEditing)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _descriptionController.text.trim().isNotEmpty
                ? _submitEntry
                : null,
            child: Text(_isEditing ? 'Save' : 'Done'),
          ),
        ],
      ),
    );
  }
}
