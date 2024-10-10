import 'package:flutter/material.dart';

/// A `BalanceEmpty` widget that displays a simple message indicating that there
/// is no balance data available.
///
/// This widget is displayed when the `BalanceCubit` is in its initial state, meaning
/// no data has been loaded yet or the balance data is empty.
class BalanceEmpty extends StatelessWidget {
  const BalanceEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    // Returns a simple `Text` widget displaying the message 'empty'.
    return const Text('empty');
  }
}
