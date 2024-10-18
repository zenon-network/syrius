import 'package:flutter/material.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class RealtimeStatisticsPopulated extends StatelessWidget {

  const RealtimeStatisticsPopulated({required this.data, super.key});
  final List<AccountBlock?> data;

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}