import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const String _kWidgetTitle = 'Realtime Stats';
final String _kWidgetDescription =
    'This card displays the number of ${kZnnCoin.symbol} and '
    '${kQsrCoin.symbol} transactions. For example, a delegation is considered a '
    '${kZnnCoin.symbol} transaction from the network\'s perspective. Every interaction '
    'with the network embedded contracts is internally considered a transaction';

class RealtimeStatistics extends StatefulWidget {
  const RealtimeStatistics({Key? key}) : super(key: key);

  @override
  State<RealtimeStatistics> createState() => _RealtimeStatisticsState();
}

class _RealtimeStatisticsState extends State<RealtimeStatistics> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<RealtimeStatisticsBloc>.reactive(
      viewModelBuilder: () => RealtimeStatisticsBloc(),
      onViewModelReady: (model) {
        model.getDataPeriodically();
      },
      builder: (_, model, __) => CardScaffold<List<AccountBlock>>(
        childStream: model.stream,
        title: _kWidgetTitle,
        description: _kWidgetDescription,
        onCompletedStatusCallback: (data) => _widgetBody(data),
      ),
    );
  }

  Widget _widgetBody(List<AccountBlock> list) {
    return Column(
      children: [
        kVerticalSpacing,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChartLegend(
              dotColor: ColorUtils.getTokenColor(kQsrCoin.tokenStandard),
              mainText: '${kQsrCoin.symbol} '
                  'transactions',
            ),
            const SizedBox(
              width: 10.0,
            ),
            ChartLegend(
              dotColor: ColorUtils.getTokenColor(kZnnCoin.tokenStandard),
              mainText: '${kZnnCoin.symbol} '
                  'transactions',
            ),
          ],
        ),
        Expanded(
          child: RealtimeTxsChart(list),
        ),
      ],
    );
  }
}
