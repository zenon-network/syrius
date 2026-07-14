import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that displays the pillar rewards
///
/// It receives updates from a [PillarRewardsHistoryBloc] and displays a
/// [_Chart] when data is available
class PillarRewardsCard extends StatelessWidget {
  /// Constructs a new instance.
  const PillarRewardsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () {
        context.read<PillarRewardsHistoryBloc>().add(
          FetchRequestData(
            address: Address.parse(kSelectedAddress!),
          ),
        );
      },
      body:
          BlocBuilder<PillarRewardsHistoryBloc, FetchState<RewardHistoryList>>(
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
    description: context.l10n.pillarRewardsDescription,
    title: context.l10n.pillarRewardsTitle,
  );
}

/// A [StandardChart] adapted to show the pillar rewards
class _Chart extends StatelessWidget {
  /// Constructs a new instance.
  const _Chart({
    required this._rewardsHistoryList,
  });

  final RewardHistoryList _rewardsHistoryList;

  @override
  Widget build(BuildContext context) {
    return StandardChart(
      maxY: _getMaxValueOfZnnRewards() < 1.0
          ? _getMaxValueOfZnnRewards().toDouble()
          : _getMaxValueOfZnnRewards().ceilToDouble(),
      lineBarsData: _linesBarData(),
      lineBarDotSymbol: kZnnCoin.symbol,
      titlesReferenceDate:
          DateTime.fromMillisecondsSinceEpoch(genesisTimestamp * 1000).add(
            Duration(
              // First epoch is zero
              days: _rewardsHistoryList.list.reversed.last.epoch + 1,
            ),
          ),
    );
  }

  List<FlSpot> _getRewardsSpots() => List<FlSpot>.generate(
    _rewardsHistoryList.list.length,
    (int index) => FlSpot(
      index.toDouble(),
      _getRewardsByIndex(index).toDouble(),
    ),
  );

  List<LineChartBarData> _linesBarData() => <LineChartBarData>[
    StandardLineChartBarData(
      color: AppColors.znnColor,
      spots: _getRewardsSpots(),
    ),
  ];

  num _getRewardsByIndex(int index) => _rewardsHistoryList.list.reversed
      .toList()[index]
      .znnAmount
      .addDecimals(
        coinDecimals,
      )
      .toNum();

  num _getMaxValueOfZnnRewards() {
    BigInt max = _rewardsHistoryList.list.first.znnAmount;
    for (final RewardHistoryEntry element in _rewardsHistoryList.list) {
      if (element.znnAmount > max) {
        max = element.znnAmount;
      }
    }
    return max.addDecimals(coinDecimals).toNum();
  }
}
