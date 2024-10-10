import 'package:flutter/material.dart';

/// A `BalanceLoading` widget that displays a loading message while the balance
/// data is being fetched.
///
/// This widget is shown when the `BalanceCubit` is in the `loading` state,
/// indicating that the balance data is currently being loaded.
class BalanceLoading extends StatelessWidget {
  const BalanceLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('loading');
  }
}
