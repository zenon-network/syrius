import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StandardLineChartBarData extends LineChartBarData {
  StandardLineChartBarData({
    required Color color,
    required List<FlSpot>? spots,
  }) : super(
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          spots: spots ?? const <FlSpot>[],
        );
}
