import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that displays the sentinel rewards history.
class SentinelRewardsCard extends StatelessWidget {
  /// Constructs a new instance.
  const SentinelRewardsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(),
      onRefreshPressed: () {
        context.read<SentinelRewardsHistoryBloc>().add(
              FetchRequestData(
                address: Address.parse(kSelectedAddress!),
              ),
            );
      },
      body: BlocBuilder<SentinelRewardsHistoryBloc,
          FetchState<RewardHistoryList>>(
        builder: (_, FetchState<RewardHistoryList> state) {
          return switch (state) {
            FetchFailure<RewardHistoryList>() => SyriusErrorWidget(
                state.exception,
              ),
            FetchInitial<RewardHistoryList>() => const SyriusLoadingWidget(),
            FetchPopulated<RewardHistoryList>() => SentinelRewardsChart(
                rewardsHistoryList: state.data,
              ),
          };
        },
      ),
    );
  }

  CardData _buildCardData() => CardData(
        description: 'This card displays a chart with your Sentinel rewards '
            'from your Sentinel Node',
        title: 'Sentinel Rewards',
      );
}
