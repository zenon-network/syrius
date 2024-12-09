import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

/// A widget that displays a loading indicator
class RealtimeStatisticsLoading extends StatelessWidget {
  /// Creates a RealtimeStatisticsLoading object.
  const RealtimeStatisticsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}
