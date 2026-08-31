import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/balance/balance.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Adds a legend to the [BalanceChart] consisting of widgets with a tooltip
/// than will show the exact balance - including decimals - available in a
/// certain coin (QSR or ZNN)
class BalanceChartLegend extends StatelessWidget {
  /// Creates a BalanceChartLegend object.
  const BalanceChartLegend({
    required this.accountInfo,
    required this.zts,
    super.key,
  });

  /// Data used for the legend
  final AccountInfo accountInfo;

  /// Coins and tokens for which to show the legend
  final List<Token> zts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const double minItemWidth = 96;
          final double itemWidth = zts.isEmpty
              ? minItemWidth
              : (constraints.maxWidth / zts.length).clamp(
                  minItemWidth,
                  double.infinity,
                );

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: zts.length,
            itemBuilder: (_, int index) => SizedBox(
              width: itemWidth,
              child: Center(
                child: _buildZtsBalanceInfo(
                  accountInfo: accountInfo,
                  coin: zts[index],
                  context: context,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  FormattedAmountWithTooltip _buildZtsBalanceInfo({
    required Token coin,
    required AccountInfo accountInfo,
    required BuildContext context,
  }) {
    return FormattedAmountWithTooltip(
      amount: accountInfo
          .getBalance(
            coin.tokenStandard,
          )
          .addDecimals(coin.decimals),
      tokenSymbol: coin.symbol,
      builder: (String amount, String tokenSymbol) => AmountInfoColumn(
        context: context,
        amount: amount,
        tokenSymbolColor: ColorUtils.getTokenColor(coin.tokenStandard),
        tokenSymbol: tokenSymbol,
      ),
    );
  }
}
