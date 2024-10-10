import 'package:flutter/material.dart';

class DualCoinStatsError extends StatelessWidget {
  final Object error;

  const DualCoinStatsError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}
