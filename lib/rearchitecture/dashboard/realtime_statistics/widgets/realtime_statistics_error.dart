import 'package:flutter/material.dart';

class RealtimeStatisticsError extends StatelessWidget {

  const RealtimeStatisticsError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}