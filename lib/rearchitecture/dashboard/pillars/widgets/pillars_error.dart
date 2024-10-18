import 'package:flutter/material.dart';

class PillarsError extends StatelessWidget {

  const PillarsError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}
