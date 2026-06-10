import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';

class StandardChart extends StatelessWidget {
  final double maxX;
  final double maxY;
  final List<LineChartBarData> lineBarsData;
  final String lineBarDotSymbol;
  final DateTime titlesReferenceDate;
  final bool convertLeftSideTitlesToInt;

  const StandardChart({
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
      margin: const EdgeInsets.all(20),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              tooltipMargin: 14,
              tooltipPadding: const EdgeInsets.all(4),
              tooltipBorderRadius: BorderRadius.circular(6),
              getTooltipColor: (LineBarSpot lineBarSpot) =>
                  Theme.of(context).colorScheme.surface,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map(
                  (LineBarSpot touchedSpot) {
                    final TextStyle textStyle = TextStyle(
                      color: touchedSpot.bar.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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
            getDrawingHorizontalLine: (_) {
              return const FlLine(
                strokeWidth: 1,
                color: Colors.black87,
                dashArray: <int>[3, 3],
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                getTitlesWidget: (double value, TitleMeta titleMeta) =>
                    SideTitleWidget(
                      meta: titleMeta,
                      fitInside: SideTitleFitInsideData.fromTitleMeta(
                        titleMeta,
                        distanceFromEdge: 0,
                      ),
                      child: Text(
                        FormatUtils.formatDate(
                          FormatUtils.subtractDaysFromDate(
                            value.toInt(),
                            titlesReferenceDate,
                          ),
                          dateFormat: 'd MMM',
                        ),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                showTitles: true,
                interval: 1,
                reservedSize: 25,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
              ),
            ),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: maxX,
          maxY: maxY,
          minY: 0,
          lineBarsData: lineBarsData,
        ),
      ),
    );
  }
}
