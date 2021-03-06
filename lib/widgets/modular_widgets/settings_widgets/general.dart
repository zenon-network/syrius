import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/settings/general_stats_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/model/general_stats.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/number_animation.dart';

class GeneralWidget extends StatefulWidget {
  const GeneralWidget({Key? key}) : super(key: key);

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
      childBuilder: () => _getStreamBuilder(),
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
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Container(height: 10.0),
              Container(
                width: 150.0,
                height: 150.0,
                child: Center(
                  child: NumberAnimation(
                    end: generalStats.frontierMomentum.height,
                    isInt: true,
                    style: Theme.of(context).textTheme.headline2,
                  ),
                ),
                decoration: const ShapeDecoration(
                  color: Colors.transparent,
                  shape: CircleBorder(
                    side: BorderSide(
                      width: 6.0,
                      color: AppColors.znnColor,
                    ),
                  ),
                ),
              ),
              Container(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  (generalStats.networkInfo.peers.isNotEmpty)
                      ? const Icon(
                          MaterialCommunityIcons.lan_connect,
                          size: 15.0,
                          color: AppColors.znnColor,
                        )
                      : const Icon(
                          MaterialCommunityIcons.lan_disconnect,
                          size: 15.0,
                          color: AppColors.errorColor,
                        ),
                  const SizedBox(
                    width: 4.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      (generalStats.networkInfo.peers.isNotEmpty)
                          ? Text(
                              'Peers connected',
                              style: Theme.of(context).textTheme.bodyText2,
                            )
                          : const Text('Peers available'),
                      const SizedBox(
                        width: 10.0,
                      ),
                      (generalStats.networkInfo.peers.isNotEmpty)
                          ? Text(
                              '${generalStats.networkInfo.peers.length}',
                              style: Theme.of(context).textTheme.subtitle1,
                            )
                          : Text(
                              'No peers found',
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                    ],
                  )
                ],
              ),
              const SizedBox(
                height: 10.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    MaterialCommunityIcons.timer,
                    size: 15.0,
                    color: AppColors.qsrColor,
                  ),
                  const SizedBox(
                    width: 4.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Timestamp',
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                    ],
                  ),
                  const SizedBox(width: 10.0),
                  Text(
                    '${generalStats.frontierMomentum.timestamp}',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ],
              ),
              const SizedBox(
                height: 6,
              ),
              RawMaterialButton(
                constraints: const BoxConstraints(
                  minHeight: 40.0,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onPressed: () => NavigationUtils.launchUrl(
                  kExplorer +
                      '/momentum/' +
                      generalStats.frontierMomentum.hash.toString(),
                  context,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Momentum hash',
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                    Container(width: 10.0),
                    const Icon(
                      MaterialCommunityIcons.compass,
                      size: 20.0,
                      color: AppColors.znnColor,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(
                        top: 12.0,
                        right: 22.0,
                        left: 22.0,
                      ),
                      child: Marquee(
                        child: Text(
                          '${generalStats.frontierMomentum.hash}',
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _getStreamBuilder() {
    return StreamBuilder<GeneralStats>(
      stream: _generalStatsBloc!.stream,
      builder: (_, snapshot) {
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
