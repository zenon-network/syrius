import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

class RealtimeStatisticsError extends StatelessWidget {

  const RealtimeStatisticsError({required this.error, super.key});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}
