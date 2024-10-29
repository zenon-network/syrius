import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class GeneralWidget extends StatefulWidget {
  const GeneralWidget({super.key});

  @override
  State createState() {
    return GeneralWidgetState();
  }
}

class GeneralWidgetState extends State<GeneralWidget> {
  GeneralStatsBloc? _generalStatsBloc;

  @override
  void initState() {
    _generalStatsBloc = GeneralStatsBloc();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'General',
      description: 'Generic wallet & network information',
      childBuilder: _getStreamBuilder,
    );
  }

  Widget _getNewBody(GeneralStats generalStats) {
    return Center(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Column(
            children: <Widget>[
              Text(
                'Momentum height',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(height: 10),
              Container(
                width: 150,
                height: 150,
                decoration: const ShapeDecoration(
                  color: Colors.transparent,
                  shape: CircleBorder(
                    side: BorderSide(
                      width: 6,
                      color: AppColors.znnColor,
                    ),
                  ),
                ),
                child: Center(
                  child: NumberAnimation(
                    end: generalStats.frontierMomentum.height,
                    isInt: true,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              Container(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (generalStats.networkInfo.peers.isNotEmpty) const Icon(
                          MaterialCommunityIcons.lan_connect,
                          size: 15,
                          color: AppColors.znnColor,
                        ) else const Icon(
                          MaterialCommunityIcons.lan_disconnect,
                          size: 15,
                          color: AppColors.errorColor,
                        ),
                  const SizedBox(
                    width: 4,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (generalStats.networkInfo.peers.isNotEmpty) Text(
                              'Peers connected',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ) else const Text('Peers available'),
                      const SizedBox(
                        width: 10,
                      ),
                      if (generalStats.networkInfo.peers.isNotEmpty) Text(
                              '${generalStats.networkInfo.peers.length}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ) else Text(
                              'No peers found',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    MaterialCommunityIcons.timer,
                    size: 15,
                    color: AppColors.qsrColor,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Timestamp',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${generalStats.frontierMomentum.timestamp}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(
                height: 6,
              ),
              RawMaterialButton(
                constraints: const BoxConstraints(
                  minHeight: 40,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: () => NavigationUtils.openUrl(
                  '$kExplorer/momentum/${generalStats.frontierMomentum.hash}',
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Momentum hash',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Container(width: 10),
                    const Icon(
                      MaterialCommunityIcons.compass,
                      size: 20,
                      color: AppColors.znnColor,
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(
                        top: 12,
                        right: 22,
                        left: 22,
                      ),
                      child: Marquee(
                        child: Text(
                          '${generalStats.frontierMomentum.hash}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getStreamBuilder() {
    return StreamBuilder<GeneralStats>(
      stream: _generalStatsBloc!.stream,
      builder: (_, AsyncSnapshot<GeneralStats> snapshot) {
        if (snapshot.hasData) {
          return _getNewBody(snapshot.data!);
        } else if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  @override
  void dispose() {
    _generalStatsBloc!.dispose();
    super.dispose();
  }
}
