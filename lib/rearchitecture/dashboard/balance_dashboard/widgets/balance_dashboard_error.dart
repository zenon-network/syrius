import 'package:flutter/material.dart';

class BalanceDashboardError extends StatelessWidget {

  const BalanceDashboardError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}
