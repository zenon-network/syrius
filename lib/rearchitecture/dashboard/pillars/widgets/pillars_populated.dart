import 'package:flutter/material.dart';

class PillarsPopulated extends StatelessWidget {

  const PillarsPopulated({required this.data, super.key});
  final int? data;

  @override
  Widget build(BuildContext context) {
    return Text(data.toString());
  }
}