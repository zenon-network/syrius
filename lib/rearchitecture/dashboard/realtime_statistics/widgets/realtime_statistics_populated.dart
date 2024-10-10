import 'package:flutter/material.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class RealtimeStatisticsPopulated extends StatelessWidget {
  final List<AccountBlock?> data;

  const RealtimeStatisticsPopulated({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}