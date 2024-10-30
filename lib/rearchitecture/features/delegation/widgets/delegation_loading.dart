import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

/// A widget that displays the apps loading indicator
class DelegationLoading extends StatelessWidget {
  /// Creates a DelegationLoading object.
  const DelegationLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}
