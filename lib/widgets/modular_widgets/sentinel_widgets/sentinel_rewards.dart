import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelRewards extends StatefulWidget {

  const SentinelRewards({
    required this.sentinelRewardsHistoryBloc,
    super.key,
  });
  final SentinelRewardsHistoryBloc sentinelRewardsHistoryBloc;

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
        padding: const EdgeInsets.all(16),
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
