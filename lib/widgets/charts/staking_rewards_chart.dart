import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StakingRewardsChart extends StatefulWidget {

  const StakingRewardsChart(
    this.rewardsHistory, {
    super.key,
  });
  final RewardHistoryList? rewardsHistory;

  @override
  State createState() => _StakingRewardsChart();
}

class _StakingRewardsChart extends State<StakingRewardsChart> {
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
          days: widget.rewardsHistory!.list.reversed.last.epoch + 1,
        ),
      ),
    );
  }

  List<FlSpot> _getRewardsSpots() => List.generate(
        widget.rewardsHistory!.list.length,
        (int index) => FlSpot(
          index.toDouble(),
          _getRewardsByIndex(index).toDouble(),
        ),
      );

  List<StandardLineChartBarData> _linesBarData() => <StandardLineChartBarData>[
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
    for (final RewardHistoryEntry element in widget.rewardsHistory!.list) {
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
