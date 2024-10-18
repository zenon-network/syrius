import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

/// A widget associated with the [DualCoinStatsState] when it's status is
/// [CubitStatus.initial] that uses the [SyriusErrorWidget] to display a message

class DualCoinStatsEmpty extends StatelessWidget {
  const DualCoinStatsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusErrorWidget('No data available');
  }
}
