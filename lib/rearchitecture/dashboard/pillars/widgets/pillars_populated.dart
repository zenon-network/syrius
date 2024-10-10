import 'package:flutter/material.dart';

class PillarsPopulated extends StatelessWidget {
  final int? data;

  const PillarsPopulated({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}