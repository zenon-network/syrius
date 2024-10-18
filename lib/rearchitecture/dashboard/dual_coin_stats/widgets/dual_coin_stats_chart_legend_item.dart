import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DualCoinStatsChartLegendItem extends StatelessWidget {

  const DualCoinStatsChartLegendItem({required this.token, super.key});
  final Token token;

  @override
  Widget build(BuildContext context) {
    return FormattedAmountWithTooltip(
      amount: token.totalSupply.addDecimals(
        token.decimals,
      ),
      tokenSymbol: token.symbol,
      builder: (amount, symbol) => AmountInfoColumn(
        amount: amount,
        tokenSymbol: symbol,
        context: context,
      ),
    );
  }
}
