import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A legend for [DualCoinStatsChartLegend]
///
/// It shows the token symbol, the amount in a shortened format - it has a
/// tooltip for showing the exact amount, including the decimals
class DualCoinStatsChartLegend extends StatelessWidget {
  /// Creates a DualCoinStatsLegend
  const DualCoinStatsChartLegend({
    required this.tokens,
    super.key,
  });

  /// Data used
  final List<Token> tokens;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = List<Widget>.generate(
      tokens.length,
      (int index) {
        final Token token = tokens[index];

        return Expanded(
          child: DualCoinStatsChartLegendItem(
            token: token,
          ),
        );
      },
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items,
    );
  }
}
