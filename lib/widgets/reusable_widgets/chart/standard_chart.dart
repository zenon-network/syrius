import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';

class StandardChart extends StatelessWidget {
  final double? yValuesInterval;
  final double maxX;
  final double maxY;
  final List<LineChartBarData> lineBarsData;
  final String lineBarDotSymbol;
  final DateTime titlesReferenceDate;
  final bool convertLeftSideTitlesToInt;

  const StandardChart({
    required this.yValuesInterval,
    required this.maxY,
    required this.lineBarsData,
    required this.titlesReferenceDate,
    this.maxX = kStandardChartNumDays - 1,
    this.lineBarDotSymbol = '',
    this.convertLeftSideTitlesToInt = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 5.0,
        right: 20.0,
        top: 20.0,
        bottom: 10.0,
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              tooltipBgColor: Theme.of(context).colorScheme.background,
              tooltipMargin: 14.0,
              tooltipPadding: const EdgeInsets.all(4.0),
              tooltipRoundedRadius: 6.0,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map(
                  (LineBarSpot touchedSpot) {
                    final textStyle = TextStyle(
                      color: touchedSpot.bar.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                    );
                    return LineTooltipItem(
                      '${touchedSpot.y == touchedSpot.y.toInt() ? touchedSpot.y.toInt() : touchedSpot.y} '
                      '$lineBarDotSymbol',
                      textStyle,
                    );
                  },
                ).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: false,
            drawVerticalLine: false,
            drawHorizontalLine: true,
            getDrawingHorizontalLine: (_) {
              return const FlLine(
                strokeWidth: 1.0,
                color: Colors.black87,
                dashArray: [3, 3],
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                getTitlesWidget: (value, titleMeta) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    FormatUtils.formatDate(
                      FormatUtils.subtractDaysFromDate(
                          value.toInt(), titlesReferenceDate),
                      dateFormat: 'd MMM',
                    ),
                    style: Theme.of(context).textTheme.titleSmall!,
                  ),
                ),
                showTitles: true,
                reservedSize: 22.0,
                interval: 1.0,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                interval: yValuesInterval,
                showTitles: true,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    value != 0
                        ? convertLeftSideTitlesToInt
                            ? '${value.toInt()}'
                            : value.toStringAsFixed(2)
                        : '',
                    style: Theme.of(context).textTheme.titleSmall!,
                  ),
                ),
                reservedSize: 26.0,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(
              showTitles: false,
            )),
          ),
          borderData: FlBorderData(show: false),
          minX: 0.0,
          maxX: maxX,
          maxY: maxY,
          minY: 0.0,
          lineBarsData: lineBarsData,
        ),
      ),
    );
  }
}
