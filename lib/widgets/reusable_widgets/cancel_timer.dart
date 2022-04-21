import 'dart:async';

import 'package:flutter/material.dart';

class CancelTimer extends StatefulWidget {
  final Duration timerDuration;
  final Color borderColor;
  final VoidCallback onTimeFinishedCallback;

  const CancelTimer(
    this.timerDuration,
    this.borderColor, {
    required this.onTimeFinishedCallback,
    Key? key,
  }) : super(key: key);

  @override
  _CancelTimerState createState() => _CancelTimerState();
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
                  seconds: 0,
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
          5.0,
        ),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 5.0,
        ),
        child: Text(
          _currentDuration.toString().split('.').first,
          style: Theme.of(context).textTheme.bodyText2,
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
