import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
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
            FetchPopulated<RewardHistoryList>() => _Chart(
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

/// A [StandardChart] adapted to show the sentinel rewards.
class _Chart extends StatelessWidget {
  /// Constructs a new instance.
  const _Chart({
    required this._rewardsHistoryList,
  });

  final RewardHistoryList _rewardsHistoryList;

  @override
  Widget build(BuildContext context) {
    return StandardChart(
      maxY: _getMaxValueOfRewards() < 1.0
          ? _getMaxValueOfRewards().toDouble()
          : _getMaxValueOfRewards().ceilToDouble(),
      lineBarsData: _linesBarData(),
      titlesReferenceDate:
      DateTime.fromMillisecondsSinceEpoch(genesisTimestamp * 1000).add(
        Duration(
          // First epoch is zero
          days: _rewardsHistoryList.list.reversed.last.epoch + 1,
        ),
      ),
    );
  }

  List<FlSpot> _getZnnRewardsSpots() => List<FlSpot>.generate(
    _rewardsHistoryList.list.length,
        (int index) => FlSpot(
      index.toDouble(),
      _getRewardsByIndex(index, kZnnCoin.tokenStandard).toDouble(),
    ),
  );

  List<FlSpot> _getQsrRewardsSpots() => List<FlSpot>.generate(
    _rewardsHistoryList.list.length,
        (int index) => FlSpot(
      index.toDouble(),
      _getRewardsByIndex(index, kQsrCoin.tokenStandard).toDouble(),
    ),
  );

  List<LineChartBarData> _linesBarData() => <LineChartBarData>[
    StandardLineChartBarData(
      color: AppColors.znnColor,
      spots: _getZnnRewardsSpots(),
    ),
    StandardLineChartBarData(
      color: AppColors.qsrColor,
      spots: _getQsrRewardsSpots(),
    ),
  ];

  num _getRewardsByIndex(int index, TokenStandard tokenId) {
    final RewardHistoryEntry entry = _rewardsHistoryList.list.reversed
        .toList()[index];
    return tokenId == kZnnCoin.tokenStandard
        ? entry.znnAmount.addDecimals(coinDecimals).toNum()
        : entry.qsrAmount.addDecimals(coinDecimals).toNum();
  }

  num _getMaxValueOfRewards() {
    final num maxZnn = _getMaxValueOfZnnRewards()
        .addDecimals(
      coinDecimals,
    )
        .toNum();
    final num maxQsr = _getMaxValueOfQsrRewards()
        .addDecimals(
      coinDecimals,
    )
        .toNum();
    return max(maxQsr, maxZnn);
  }

  BigInt _getMaxValueOfZnnRewards() {
    BigInt max = _rewardsHistoryList.list.first.znnAmount;
    for (final RewardHistoryEntry element in _rewardsHistoryList.list) {
      if (element.znnAmount > max) {
        max = element.znnAmount;
      }
    }
    return max;
  }

  BigInt _getMaxValueOfQsrRewards() {
    BigInt max = _rewardsHistoryList.list.first.qsrAmount;
    for (final RewardHistoryEntry element in _rewardsHistoryList.list) {
      if (element.qsrAmount > max) {
        max = element.qsrAmount;
      }
    }
    return max;
  }
}
