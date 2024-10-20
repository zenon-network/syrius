import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

class RealtimeStatisticsEmpty extends StatelessWidget {
  const RealtimeStatisticsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyriusErrorWidget('No data available');
  }
}
