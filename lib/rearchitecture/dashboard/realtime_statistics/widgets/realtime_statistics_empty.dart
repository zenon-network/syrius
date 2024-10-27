import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

/// A widget that displays a hardcoded error message
class RealtimeStatisticsEmpty extends StatelessWidget {
  /// Creates a RealtimeStatisticsEmpty object.
  const RealtimeStatisticsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(context.l10n.waitingForDataFetching);
  }
}
