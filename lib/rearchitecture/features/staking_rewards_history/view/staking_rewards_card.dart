import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that displays the staking rewards history.
class StakingRewardsCard extends StatelessWidget {
  /// Constructs a new instance.
  const StakingRewardsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () {
        context.read<StakingRewardsHistoryBloc>().add(
          FetchRequestData(
            address: Address.parse(kSelectedAddress!),
          ),
        );
      },
      body:
          BlocBuilder<StakingRewardsHistoryBloc, FetchState<RewardHistoryList>>(
            builder: (_, FetchState<RewardHistoryList> state) {
              return switch (state) {
                FetchFailure<RewardHistoryList>() => SyriusErrorWidget(
                  state.exception,
                ),
                FetchInitial<RewardHistoryList>() =>
                  const SyriusLoadingWidget(),
                FetchPopulated<RewardHistoryList>() => _Chart(
                  rewardsHistoryList: state.data,
                ),
              };
            },
          ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    description: context.l10n.stakingRewardsDescription,
    title: context.l10n.stakingRewardsTitle,
  );
}

/// A [StandardChart] adapted to show the staking rewards.
class _Chart extends StatelessWidget {
  /// Constructs a new instance.
  const _Chart({
    required this.rewardsHistoryList,
  });

  final RewardHistoryList rewardsHistoryList;

  @override
  Widget build(BuildContext context) {
    return StandardChart(
      maxY: _getMaxValueOfQsrRewards() < 1.0
          ? _getMaxValueOfQsrRewards().toDouble()
          : _getMaxValueOfQsrRewards().ceilToDouble(),
      lineBarsData: _linesBarData(),
      lineBarDotSymbol: kQsrCoin.symbol,
      titlesReferenceDate:
          DateTime.fromMillisecondsSinceEpoch(genesisTimestamp * 1000).add(
            Duration(
              // First epoch is zero
              days: rewardsHistoryList.list.reversed.last.epoch + 1,
            ),
          ),
    );
  }

  List<FlSpot> _getRewardsSpots() => List<FlSpot>.generate(
    rewardsHistoryList.list.length,
    (int index) => FlSpot(
      index.toDouble(),
      _getRewardsByIndex(index).toDouble(),
    ),
  );

  List<LineChartBarData> _linesBarData() => <LineChartBarData>[
    StandardLineChartBarData(
      color: AppColors.qsrColor,
      spots: _getRewardsSpots(),
    ),
  ];

  num _getRewardsByIndex(int index) => rewardsHistoryList.list.reversed
      .toList()[index]
      .qsrAmount
      .addDecimals(
        coinDecimals,
      )
      .toNum();

  num _getMaxValueOfQsrRewards() {
    BigInt max = rewardsHistoryList.list.first.qsrAmount;
    for (final RewardHistoryEntry element in rewardsHistoryList.list) {
      if (element.qsrAmount > max) {
        max = element.qsrAmount;
      }
    }
    return max
        .addDecimals(
          coinDecimals,
        )
        .toNum();
  }
}
