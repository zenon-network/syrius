import 'dart:async';

import 'package:flutter/material.dart';

class CancelTimer extends StatefulWidget {

  const CancelTimer(
    this.timerDuration,
    this.borderColor, {
    required this.onTimeFinishedCallback,
    super.key,
  });
  final Duration timerDuration;
  final Color borderColor;
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
      (v) {
        if (mounted &&
            _currentDuration >
                const Duration(
                  
                )) {
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
