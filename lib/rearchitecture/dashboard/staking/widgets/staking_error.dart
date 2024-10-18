import 'package:flutter/material.dart';

class StakingError extends StatelessWidget {

  const StakingError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}