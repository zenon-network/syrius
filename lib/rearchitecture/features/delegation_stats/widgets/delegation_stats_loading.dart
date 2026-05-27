import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

/// A widget that displays the apps loading indicator
class DelegationStatsLoading extends StatelessWidget {
  /// Creates a DelegationLoading object.
  const DelegationStatsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}
