import 'package:flutter/material.dart';

class StakingError extends StatelessWidget {
  final Object error;

  const StakingError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}