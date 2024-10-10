import 'package:flutter/material.dart';

class DelegationError extends StatelessWidget {
  final Object error;

  const DelegationError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}
