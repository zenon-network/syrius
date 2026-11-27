import 'dart:async';

import 'package:flutter/material.dart';

/// Displays a bordered countdown timer that triggers a callback on completion.
class CancelTimer extends StatefulWidget {
  /// Creates a [CancelTimer].
  const CancelTimer(
    this.timerDuration,
    this.borderColor, {
    required this.onTimeFinishedCallback,
    super.key,
  });

  /// Initial duration to count down from.
  final Duration timerDuration;

  /// Color of the container border around the timer text.
  final Color borderColor;

  /// Callback invoked once the countdown reaches zero.
  final VoidCallback onTimeFinishedCallback;

  @override
  State<CancelTimer> createState() => _CancelTimerState();
}

class _CancelTimerState extends State<CancelTimer> {
  late Duration _currentDuration;
  late Color _borderColor;
  late Timer _countDownTimer;

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.timerDuration;
    _borderColor = widget.borderColor;
    _countDownTimer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (Timer v) {
        if (mounted && _currentDuration > Duration.zero) {
          setState(() {
            _currentDuration = _currentDuration -
                const Duration(
                  seconds: 1,
                );
          });
        } else if (mounted) {
          widget.onTimeFinishedCallback();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          5,
        ),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        child: Text(
          _currentDuration.toString().split('.').first,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countDownTimer.cancel();
    super.dispose();
  }
}
