import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Pre-styled [LineChartBarData] with a gradient fill below the line.
class StandardLineChartBarData extends LineChartBarData {
  /// Creates a [StandardLineChartBarData] with the given [color] and [spots].
  StandardLineChartBarData({
    required Color color,
    required List<FlSpot>? spots,
  }) : super(
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
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
