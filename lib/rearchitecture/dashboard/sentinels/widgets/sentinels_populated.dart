import 'package:flutter/material.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelsPopulated extends StatelessWidget {
  final SentinelInfoList? data;

  const SentinelsPopulated({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}