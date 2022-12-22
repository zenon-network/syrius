import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class StandardLineChartBarData extends LineChartBarData {
  StandardLineChartBarData({
    required Color color,
    required List<FlSpot>? spots,
  }) : super(
          spots: spots,
          isCurved: false,
          color: color,
          barWidth: 3.0,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.znnColor.withOpacity(0.5),
                AppColors.znnColor.withOpacity(0.0),
              ],
              stops: const [0.1, 1.0],

            ),
          ),
        );
}
