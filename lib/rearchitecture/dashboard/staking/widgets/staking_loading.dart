import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget associated with the [StakingState] when it's status is
/// [DashboardStatus.loading] that uses the [SyriusLoadingWidget] to display a
/// loading indicator.
class StakingLoading extends StatelessWidget {
  /// Creates a StakingLoading object.
  const StakingLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}
