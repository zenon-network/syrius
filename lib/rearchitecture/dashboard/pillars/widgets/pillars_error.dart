import 'package:flutter/material.dart';

class PillarsError extends StatelessWidget {
  final Object error;

  const PillarsError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}
