import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

/// A `BalanceLoading` widget that displays a loading message while the balance
/// data is being fetched.
///
/// This widget is shown when the `BalanceCubit` is in the `loading` state,
/// indicating that the balance data is currently being loaded.
class BalanceLoading extends StatelessWidget {
  const BalanceLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}
