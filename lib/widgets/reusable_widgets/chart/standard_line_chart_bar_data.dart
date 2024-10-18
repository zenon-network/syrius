import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StandardLineChartBarData extends LineChartBarData {
  StandardLineChartBarData({
    required Color color,
    required List<FlSpot>? spots,
  }) : super(
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          spots: spots ?? const [],
        );
}
