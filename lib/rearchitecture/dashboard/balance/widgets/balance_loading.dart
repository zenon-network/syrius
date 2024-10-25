import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

/// A widget that displays a loading message while the balance data is being
/// fetched.
///
/// This widget is shown when the [BalanceCubit] sends a [BalanceState] update
/// with a status of [DashboardStatus.loading], indicating that the balance
/// data is currently being loaded.
class BalanceLoading extends StatelessWidget {
  /// Creates a BalanceLoading object.
  const BalanceLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}
