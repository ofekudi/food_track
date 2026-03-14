import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/strings.dart';
import 'add_entry_screen.dart';

class MindfulnessTimerScreen extends StatefulWidget {
  final DateTime targetDate;

  const MindfulnessTimerScreen({
    super.key,
    required this.targetDate,
  });

  @override
  State<MindfulnessTimerScreen> createState() => _MindfulnessTimerScreenState();
}

class _MindfulnessTimerScreenState extends State<MindfulnessTimerScreen>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 5;

  late int _secondsRemaining;
  late String _message;
  Timer? _timer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _totalSeconds;
    _message = AppStrings.mindfulnessMessages[
        Random().nextInt(AppStrings.mindfulnessMessages.length)];

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalSeconds),
    )..forward();

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        _navigateToAddEntry();
      }
    });
  }

  void _navigateToAddEntry() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddEntryScreen(targetDate: widget.targetDate),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Circular countdown
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    // Animated progress
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return CircularProgressIndicator(
                            value: 1.0 - _animationController.value,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            color: theme.colorScheme.primary,
                          );
                        },
                      ),
                    ),
                    // Countdown number
                    Text(
                      '$_secondsRemaining',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              // Mindfulness message
              Text(
                _message,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Subtle hint at bottom
              Text(
                AppStrings.mindfulnessPausing,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
