import 'package:flutter/material.dart';

class TotalHourlyTransactionsError extends StatelessWidget {
  final Object error;

  const TotalHourlyTransactionsError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}
