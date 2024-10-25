import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget associated with the [DualCoinStatsState] when it's status is
/// [DashboardStatus.success] that displays the data provided using a chart
/// - [DualCoinStatsChart] - and a legend - [DualCoinStatsChartLegend]

class DualCoinStatsPopulated extends StatefulWidget {

  /// Creates a DualCoinStatsPopulated widget
  const DualCoinStatsPopulated({
    required this.tokens,
    super.key,
  });

  /// The list of [Token] that will provide data for the chart
  final List<Token> tokens;

  @override
  State<DualCoinStatsPopulated> createState() => _DualCoinStatsPopulatedState();
}

class _DualCoinStatsPopulatedState extends State<DualCoinStatsPopulated>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<int?> _touchedSectionIndexNotifier = ValueNotifier(null);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: DualCoinStatsChart(
            tokenList: widget.tokens,
            touchedSectionIndexNotifier: _touchedSectionIndexNotifier,
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8),
          child: DualCoinStatsChartLegend(
            tokens: widget.tokens,
          ),
        ),
      ],
    );
  }
}
