import 'package:flutter/material.dart';

class BalanceDashboardError extends StatelessWidget {
  final Object error;

  const BalanceDashboardError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}
