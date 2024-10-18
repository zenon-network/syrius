import 'package:flutter/material.dart';

class SentinelsError extends StatelessWidget {

  const SentinelsError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}