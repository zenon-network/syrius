import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelRewardsChart extends StatefulWidget {
  final RewardHistoryList? rewardsHistory;

  const SentinelRewardsChart(
    this.rewardsHistory, {
    Key? key,
  }) : super(key: key);

  @override
  State createState() {
    return _SentinelRewardsChart();
  }
}

class _SentinelRewardsChart extends State<SentinelRewardsChart> {
  @override
  Widget build(BuildContext context) {
    return StandardChart(
      yValuesInterval: _getMaxValueOfRewards() > kNumOfChartLeftSideTitles
          ? _getMaxValueOfRewards() / kNumOfChartLeftSideTitles
          : null,
      maxY: _getMaxValueOfRewards() < 1.0
          ? _getMaxValueOfRewards().toDouble()
          : _getMaxValueOfRewards().ceilToDouble(),
      lineBarsData: _linesBarData(),
      titlesReferenceDate:
          DateTime.fromMillisecondsSinceEpoch(genesisTimestamp * 1000).add(
        Duration(
          // First epoch is zero
          days: widget.rewardsHistory!.list.reversed.last.epoch + 1,
        ),
      ),
    );
  }

  List<FlSpot> _getZnnRewardsSpots() => List.generate(
        widget.rewardsHistory!.list.length,
        (index) => FlSpot(
          index.toDouble(),
          _getRewardsByIndex(index, kZnnCoin.tokenStandard).toDouble(),
        ),
      );

  List<FlSpot> _getQsrRewardsSpots() => List.generate(
        widget.rewardsHistory!.list.length,
        (index) => FlSpot(
          index.toDouble(),
          _getRewardsByIndex(index, kQsrCoin.tokenStandard).toDouble(),
        ),
      );

  List<LineChartBarData> _linesBarData() => [
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
    return tokenId == kZnnCoin.tokenStandard
        ? widget.rewardsHistory!.list.reversed
            .toList()[index]
            .znnAmount
            .addDecimals(
              coinDecimals,
            )
            .toNum()
        : widget.rewardsHistory!.list.reversed
            .toList()[index]
            .qsrAmount
            .addDecimals(
              coinDecimals,
            )
            .toNum();
  }

  num _getMaxValueOfRewards() {
    num maxZnn = _getMaxValueOfZnnRewards()
        .addDecimals(
          coinDecimals,
        )
        .toNum();
    num maxQsr = _getMaxValueOfQsrRewards()
        .addDecimals(
          coinDecimals,
        )
        .toNum();
    return max(maxQsr, maxZnn);
  }

  BigInt _getMaxValueOfZnnRewards() {
    BigInt max = widget.rewardsHistory!.list.first.znnAmount;
    for (var element in widget.rewardsHistory!.list) {
      if (element.znnAmount > max) {
        max = element.znnAmount;
      }
    }
    return max;
  }

  BigInt _getMaxValueOfQsrRewards() {
    BigInt max = widget.rewardsHistory!.list.first.qsrAmount;
    for (var element in widget.rewardsHistory!.list) {
      if (element.qsrAmount > max) {
        max = element.qsrAmount;
      }
    }
    return max;
  }
}
