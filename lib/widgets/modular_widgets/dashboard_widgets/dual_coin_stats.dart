import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const String _kWidgetTitle = 'Dual Coin Stats';
final String _kWidgetDescription = 'This card displays the circulating '
    '${kZnnCoin.symbol} and ${kQsrCoin.symbol} supply from the network';

class DualCoinStats extends StatefulWidget {
  const DualCoinStats({
    super.key,
  });

  @override
  State<DualCoinStats> createState() => _DualCoinStatsState();
}

class _DualCoinStatsState extends State<DualCoinStats>
    with SingleTickerProviderStateMixin {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DualCoinStatsBloc>.reactive(
      viewModelBuilder: DualCoinStatsBloc.new,
      onViewModelReady: (model) {
        model.getDataPeriodically();
      },
      builder: (_, model, __) => CardScaffold<List<Token?>>(
        description: _kWidgetDescription,
        childStream: model.stream,
        onCompletedStatusCallback: _getWidgetBody,
        title: _kWidgetTitle,
      ),
    );
  }

  Widget _getWidgetBody(List<Token?> tokenList) {
    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: StandardPieChart(
              sectionsSpace: 4,
              centerSpaceRadius: 0,
              sections: showingSections(tokenList),
              onChartSectionTouched: (pieTouchedSection) {
                setState(() {
                  _touchedIndex = pieTouchedSection?.touchedSectionIndex;
                });
              },
            ),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
                child: _getTokenSupplyInfoWidget(tokenList[0]!),
              ),
              Expanded(
                child: _getTokenSupplyInfoWidget(tokenList[1]!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  FormattedAmountWithTooltip _getTokenSupplyInfoWidget(Token token) {
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

  List<PieChartSectionData> showingSections(List<Token?> tokenList) {
    final totalSupply = tokenList.fold<BigInt>(
      BigInt.zero,
      (previousValue, element) => previousValue + element!.totalSupply,
    );
    return List.generate(
      tokenList.length,
      (i) {
        final currentTokenInfo = tokenList[i]!;
        final isTouched = i == _touchedIndex;
        final opacity = isTouched ? 1.0 : 0.5;
        return PieChartSectionData(
          color: ColorUtils.getTokenColor(currentTokenInfo.tokenStandard)
              .withOpacity(opacity),
          value: currentTokenInfo.totalSupply / totalSupply,
          title: currentTokenInfo.symbol,
          radius: 60,
          titleStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Colors.white,
              ),
        );
      },
    );
  }
}
