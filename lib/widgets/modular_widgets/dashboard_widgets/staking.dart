import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const String _kWidgetTitle = 'Staking Stats';
final String _kWidgetDescription = 'This card displays the number of staking '
    'entries and the total ${kZnnCoin.symbol} that you are currently staking';

class Staking extends StatefulWidget {
  const Staking({Key? key}) : super(key: key);

  @override
  State<Staking> createState() => _StakingState();
}

class _StakingState extends State<Staking> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<StakingBloc>.reactive(
      viewModelBuilder: () => StakingBloc(),
      onViewModelReady: (model) {
        model.getDataPeriodically();
      },
      builder: (_, model, __) => CardScaffold<StakingStatsModel>(
        childStream: model.stream,
        onCompletedStatusCallback: (data) => _widgetBody(data),
        title: _kWidgetTitle,
        description: _kWidgetDescription,
      ),
    );
  }

  Widget _widgetBody(StakingStatsModel stake) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8.0),
          width: 36.0,
          height: 36.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.znnColor,
            ),
          ),
          child: Icon(
            SimpleLineIcons.energy,
            size: 12.0,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        Container(width: 16.0),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NumberAnimation(
              end: stake.numActiveStakingEntries,
              isInt: true,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              '${stake.totalZnnStakingAmount.addDecimals(coinDecimals)} ${kZnnCoin.symbol}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
