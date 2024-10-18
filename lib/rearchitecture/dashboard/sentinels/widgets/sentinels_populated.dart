import 'package:flutter/material.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelsPopulated extends StatelessWidget {

  const SentinelsPopulated({required this.data, super.key});
  final SentinelInfoList? data;

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}