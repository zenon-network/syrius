import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A [StandardChart] adapted to show the sentinel rewards.
class SentinelRewardsChart extends StatelessWidget {
  /// Constructs a new instance.
  const SentinelRewardsChart({
    required this._rewardsHistoryList,
    super.key,
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
