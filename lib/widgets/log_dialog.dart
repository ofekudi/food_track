import 'package:flutter/material.dart';
import '../constants/insights.dart';
import '../constants/strings.dart';
import '../models/meal_slot.dart';

/// The one place anything gets logged: a field and a row of things you're
/// likely to pick.
///
/// No heading, no labels — the slot you tapped is already on screen behind the
/// dialog, and a chip explains itself. A centred dialog rather than a bottom
/// sheet, so the keyboard insets it instead of shoving it around.
///
/// Nothing here blocks — no timer, no cap, no confirmation. The failure mode
/// this app guards against is not logging at all.
class LogDialog extends StatefulWidget {
  final MealSlot slot;
  final String? initialText;

  const LogDialog({super.key, required this.slot, this.initialText});

  @override
  State<LogDialog> createState() => _LogDialogState();
}

class _LogDialogState extends State<LogDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText ?? '');

  bool get _canSave => _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSave) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  /// Appends rather than replaces, so a meal can be built from more than one
  /// chip — "Home Special" then "Shake" gives "Home Special, Shake".
  void _use(String chip) {
    final current = _controller.text.trim();
    final text = current.isEmpty ? chip : '$current, $chip';
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final chips = AppInsights.ideasFor(widget.slot);

    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: AppStrings.logHint,
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final chip in chips)
                    ActionChip(
                      label: Text(chip),
                      onPressed: () => _use(chip),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _canSave ? _submit : null,
          child: const Text(AppStrings.save),
        ),
      ],
    );
  }
}
