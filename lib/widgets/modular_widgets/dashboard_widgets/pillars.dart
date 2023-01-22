import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const String _kWidgetTitle = 'Pillars';
const String _kWidgetDescription = 'This card displays the number of active '
    'Pillars in the network';

class Pillars extends StatefulWidget {
  const Pillars({
    Key? key,
  }) : super(key: key);

  @override
  State<Pillars> createState() => _PillarsState();
}

class _PillarsState extends State<Pillars> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<PillarsBloc>.reactive(
      viewModelBuilder: () => PillarsBloc(),
      onViewModelReady: (model) {
        model.getDataPeriodically();
      },
      builder: (_, model, __) => CardScaffold<int>(
        childStream: model.stream,
        onCompletedStatusCallback: (data) => _widgetBody(data),
        title: _kWidgetTitle,
        description: _kWidgetDescription,
      ),
    );
  }

  _widgetBody(int numOfPillars) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SvgPicture.asset(
          'assets/svg/ic_pillars_dashboard.svg',
          width: 65.0,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NumberAnimation(
              end: numOfPillars,
              isInt: true,
              style: Theme.of(context).textTheme.headline2,
            ),
            Text(
              'Active Pillars',
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ],
        ),
      ],
    );
  }
}
