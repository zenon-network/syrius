import 'package:flutter/material.dart';

class TotalHourlyTransactionsPopulated extends StatelessWidget {

  const TotalHourlyTransactionsPopulated({required this.data, super.key});
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}
