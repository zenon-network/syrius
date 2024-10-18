import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/balance/widgets/balance_chart.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Adds a legend to the [BalanceChart] consisting of widgets with a tooltip
/// than will show the exact balance - including decimals - available in a
/// certain coin (QSR or ZNN)

class BalanceChartLegend extends StatelessWidget {

  const BalanceChartLegend({required this.accountInfo, super.key});
  final AccountInfo accountInfo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _getCoinBalanceInfo(
            accountInfo: accountInfo,
            coin: kZnnCoin,
            context: context,
          ),
        ),
        Expanded(
          child: _getCoinBalanceInfo(
            accountInfo: accountInfo,
            coin: kQsrCoin,
            context: context,
          ),
        ),
      ],
    );
  }

  FormattedAmountWithTooltip _getCoinBalanceInfo({
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
      builder: (amount, tokenSymbol) => AmountInfoColumn(
        context: context,
        amount: amount,
        tokenSymbol: tokenSymbol,
      ),
    );
  }
}
