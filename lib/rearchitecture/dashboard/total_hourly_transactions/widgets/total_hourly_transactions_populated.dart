import 'package:flutter/material.dart';

class TotalHourlyTransactionsPopulated extends StatelessWidget {
  final Map<String, dynamic>? data;

  const TotalHourlyTransactionsPopulated({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}
