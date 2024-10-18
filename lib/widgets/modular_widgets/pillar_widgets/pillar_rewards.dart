import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarRewards extends StatefulWidget {

  const PillarRewards({required this.pillarRewardsHistoryBloc, super.key});
  final PillarRewardsHistoryBloc pillarRewardsHistoryBloc;

  @override
  State createState() => _PillarRewardsState();
}

class _PillarRewardsState extends State<PillarRewards> {
  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Pillar Rewards',
      description: 'This card displays a chart with your Pillar rewards. '
          'Pillar rewards are generated either by operating a Pillar Node or from '
          'delegations to a Pillar Node',
      childBuilder: () => Padding(
        padding: const EdgeInsets.all(16),
        child: _getStreamBody(),
      ),
    );
  }

  Widget _getStreamBody() {
    return StreamBuilder<RewardHistoryList?>(
      stream: widget.pillarRewardsHistoryBloc.stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return PillarRewardsChart(snapshot.data);
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }
}
