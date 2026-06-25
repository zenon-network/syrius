import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A [StandardChart] adapted to show the pillar rewards
class PillarRewardsChart extends StatelessWidget {
  /// Constructs a new instance.
  const PillarRewardsChart({
    required RewardHistoryList rewardsHistoryList,
    super.key,
  }) : _rewardsHistoryList = rewardsHistoryList;

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
