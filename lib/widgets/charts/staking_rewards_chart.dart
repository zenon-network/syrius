import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StakingRewardsChart extends StatefulWidget {
  final RewardHistoryList? rewardsHistory;

  const StakingRewardsChart(
    this.rewardsHistory, {
    Key? key,
  }) : super(key: key);

  @override
  State createState() => _StakingRewardsChart();
}

class _StakingRewardsChart extends State<StakingRewardsChart> {
  @override
  Widget build(BuildContext context) {
    return StandardChart(
      yValuesInterval: _getMaxValueOfQsrRewards() > kNumOfChartLeftSideTitles
          ? _getMaxValueOfQsrRewards() / kNumOfChartLeftSideTitles
          : null,
      maxY: _getMaxValueOfQsrRewards() < 1.0
          ? _getMaxValueOfQsrRewards().toDouble()
          : _getMaxValueOfQsrRewards().ceilToDouble(),
      lineBarsData: _linesBarData(),
      lineBarDotSymbol: kQsrCoin.symbol,
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

  _linesBarData() => [
        StandardLineChartBarData(
          color: AppColors.qsrColor,
          spots: _getRewardsSpots(),
        ),
      ];

  num _getRewardsByIndex(int index) => widget.rewardsHistory!.list.reversed
      .toList()[index]
      .qsrAmount
      .addDecimals(
        coinDecimals,
      )
      .toNum();

  num _getMaxValueOfQsrRewards() {
    BigInt max = widget.rewardsHistory!.list.first.qsrAmount;
    for (var element in widget.rewardsHistory!.list) {
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
