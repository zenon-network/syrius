import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const String _kWidgetTitle = 'Delegation Stats';
final String _kWidgetDescription = 'This card displays the amount of '
    '${kZnnCoin.symbol} and the name of the Pillar that you delegated to';

class DelegationStats extends StatefulWidget {
  const DelegationStats({Key? key}) : super(key: key);

  @override
  State<DelegationStats> createState() => _DelegationStatsState();
}

class _DelegationStatsState extends State<DelegationStats> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DelegationBloc>.reactive(
      viewModelBuilder: () => DelegationBloc(),
      onViewModelReady: (model) {
        model.getDataPeriodically();
      },
      builder: (_, model, __) => CardScaffold<DelegationInfo>(
        childStream: model.stream,
        onCompletedStatusCallback: (data) => _getWidgetBody(data),
        title: _kWidgetTitle,
        description: _kWidgetDescription,
      ),
    );
  }

  Widget _getWidgetBody(DelegationInfo delegationInfo) {
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
              color: delegationInfo.status == 1
                  ? AppColors.znnColor
                  : AppColors.errorColor,
            ),
          ),
          child: Icon(
            SimpleLineIcons.trophy,
            size: 12.0,
            color: Theme.of(context).textTheme.bodyLarge!.color,
          ),
        ),
        Container(width: 16.0),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              delegationInfo.name.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${delegationInfo.weight.addDecimals(coinDecimals)} ${kZnnCoin.symbol}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
