import 'package:flutter/material.dart';

class TotalHourlyTransactionsError extends StatelessWidget {

  const TotalHourlyTransactionsError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}
