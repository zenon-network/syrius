import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const String _kWidgetTitle = 'Sentinels';
const String _kWidgetDescription = 'This card displays the number of active '
    'Sentinels in the network';

class Sentinels extends StatefulWidget {
  const Sentinels({super.key});

  @override
  State<Sentinels> createState() => _SentinelsState();
}

class _SentinelsState extends State<Sentinels> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SentinelsBloc>.reactive(
      viewModelBuilder: SentinelsBloc.new,
      onViewModelReady: (model) {
        model.getDataPeriodically();
      },
      builder: (_, model, __) => CardScaffold<List<SentinelInfo>>(
        childStream: model.stream,
        onCompletedStatusCallback: _getWidgetBody,
        title: _kWidgetTitle,
        description: _kWidgetDescription,
      ),
    );
  }

  Widget _getWidgetBody(List<SentinelInfo> sentinelsByCycle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(
            'assets/svg/ic_sentinels_dashboard.svg',
            width: 42,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NumberAnimation(
              end: sentinelsByCycle.length,
              isInt: true,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Active Sentinels',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
