import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

/// A widget associated with the [DualCoinStatsState] when it's status is
/// [CubitStatus.loading] that uses the [SyriusLoadingWidget] to display a
/// loading indicator

class DualCoinStatsLoading extends StatelessWidget {
  const DualCoinStatsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}
