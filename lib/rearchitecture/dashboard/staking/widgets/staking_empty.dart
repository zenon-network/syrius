import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget associated with the [StakingState] when it's status is
/// [DashboardStatus.initial] that uses the [SyriusErrorWidget] to display a message
class StakingEmpty extends StatelessWidget {
  const StakingEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusErrorWidget('No data available');
  }
}
