import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class StandardLineChartBarData extends LineChartBarData {
  StandardLineChartBarData({
    required List<Color> colors,
    required List<FlSpot>? spots,
  }) : super(
          spots: spots,
          isCurved: false,
          colors: colors,
          barWidth: 3.0,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
          ),
          belowBarData: BarAreaData(
            show: true,
            colors: [
              AppColors.znnColor.withOpacity(0.5),
              AppColors.znnColor.withOpacity(0.0),
            ],
            gradientColorStops: [0.1, 1.0],
            gradientTo: const Offset(0.0, 1.0),
          ),
        );
}
