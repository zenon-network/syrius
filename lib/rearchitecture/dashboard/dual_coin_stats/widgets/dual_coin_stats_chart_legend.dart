import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A legend for [DualCoinStatsChartLegend]
///
/// It shows the token symbol, the amount in a shortened format - it has a
/// tooltip for showing the exact amount, including the decimals

class DualCoinStatsChartLegend extends StatelessWidget {

  const DualCoinStatsChartLegend({
    required this.tokens,
    super.key,
  });
  final List<Token> tokens;

  @override
  Widget build(BuildContext context) {
    final items = List<Widget>.generate(
      tokens.length,
      (index) {
        final token = tokens[index];

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
