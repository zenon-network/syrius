import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarRewardsChart extends StatefulWidget {
  final RewardHistoryList? rewardsHistory;

  const PillarRewardsChart(
    this.rewardsHistory, {
    Key? key,
  }) : super(key: key);

  @override
  State createState() => PillarRewardsChartState();
}

class PillarRewardsChartState extends State<PillarRewardsChart> {
  @override
  Widget build(BuildContext context) {
    return StandardChart(
      yValuesInterval: _getMaxValueOfZnnRewards() > kNumOfChartLeftSideTitles
          ? _getMaxValueOfZnnRewards() / kNumOfChartLeftSideTitles
          : null,
      maxY: _getMaxValueOfZnnRewards() < 1.0
          ? _getMaxValueOfZnnRewards().toDouble()
          : _getMaxValueOfZnnRewards().ceilToDouble(),
      lineBarsData: _linesBarData(),
      lineBarDotSymbol: kZnnCoin.symbol,
      titlesReferenceDate:
          DateTime.fromMillisecondsSinceEpoch(genesisTimestamp * 1000).add(
        Duration(
          // First epoch is zero
          days: widget.rewardsHistory!.list.reversed.last.epoch + 1,
        ),
      ),
    );
  }

  List<FlSpot> _getRewardsSpots() => List.generate(
        widget.rewardsHistory!.list.length,
        (index) => FlSpot(
          index.toDouble(),
          _getRewardsByIndex(index).toDouble(),
        ),
      );

  List<LineChartBarData> _linesBarData() => [
        StandardLineChartBarData(
          color: AppColors.znnColor,
          spots: _getRewardsSpots(),
        ),
      ];

  num _getRewardsByIndex(int index) => widget.rewardsHistory!.list.reversed
      .toList()[index]
      .znnAmount
      .addDecimals(
        coinDecimals,
      )
      .toNum();

  num _getMaxValueOfZnnRewards() {
    BigInt? max = widget.rewardsHistory!.list.first.znnAmount;
    for (var element in widget.rewardsHistory!.list) {
      if (element.znnAmount > max!) {
        max = element.znnAmount;
      }
    }
    return max!.addDecimals(coinDecimals).toNum();
  }
}
