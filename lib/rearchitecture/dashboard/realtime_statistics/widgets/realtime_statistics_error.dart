import 'package:flutter/material.dart';

class RealtimeStatisticsError extends StatelessWidget {
  final Object error;

  const RealtimeStatisticsError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}