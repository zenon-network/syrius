import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/charts/sentinel_rewards_chart.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelRewards extends StatefulWidget {
  final SentinelRewardsHistoryBloc sentinelRewardsHistoryBloc;

  const SentinelRewards({
    required this.sentinelRewardsHistoryBloc,
    Key? key,
  }) : super(key: key);

  @override
  State createState() {
    return _SentinelRewardsState();
  }
}

class _SentinelRewardsState extends State<SentinelRewards> {
  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Sentinel Rewards',
      description: 'This card displays a chart with your Sentinel rewards from '
          'your Sentinel Node',
      childBuilder: () => Padding(
        padding: const EdgeInsets.all(16.0),
        child: _getStreamBody(),
      ),
    );
  }

  Widget _getStreamBody() {
    return StreamBuilder<RewardHistoryList?>(
      stream: widget.sentinelRewardsHistoryBloc.stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return SentinelRewardsChart(snapshot.data);
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }
}
