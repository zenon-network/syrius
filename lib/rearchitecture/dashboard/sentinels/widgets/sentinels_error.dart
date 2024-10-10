import 'package:flutter/material.dart';

class SentinelsError extends StatelessWidget {
  final Object error;

  const SentinelsError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}