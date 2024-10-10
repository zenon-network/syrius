import 'package:flutter/material.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DualCoinStatsPopulated extends StatelessWidget {
  final List<Token?> data;

  const DualCoinStatsPopulated({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}
