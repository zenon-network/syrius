import 'package:flutter/material.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StakingPopulated extends StatelessWidget {
  final StakeList? data;

  const StakingPopulated({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}