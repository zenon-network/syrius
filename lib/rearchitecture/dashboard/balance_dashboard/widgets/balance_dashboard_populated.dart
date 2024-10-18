import 'package:flutter/material.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class BalanceDashboardPopulated extends StatelessWidget {

  const BalanceDashboardPopulated({required this.data, super.key});
  final AccountInfo? data;

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}
