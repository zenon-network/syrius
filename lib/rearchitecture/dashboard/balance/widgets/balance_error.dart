import 'package:flutter/material.dart';

/// A `BalanceError` widget that displays an error message when the balance
/// data fetching fails.
///
/// This widget is displayed when the `BalanceCubit` encounters an error
/// while trying to load the balance data.
class BalanceError extends StatelessWidget {
  final Object error;

  const BalanceError({required this.error, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(error.toString());
  }
}
