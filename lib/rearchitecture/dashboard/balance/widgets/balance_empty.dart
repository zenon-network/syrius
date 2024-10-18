import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

/// A `BalanceEmpty` widget that displays a simple message indicating that there
/// is no balance data available.
///
/// This widget is displayed when the `BalanceCubit` is in its initial state, meaning
/// no data has been loaded yet or the balance data is empty.
class BalanceEmpty extends StatelessWidget {
  const BalanceEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusErrorWidget('No data available');
  }
}
