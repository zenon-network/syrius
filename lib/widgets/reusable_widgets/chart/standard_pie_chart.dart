import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StandardPieChart extends PieChart {
  final List<PieChartSectionData> sections;
  final void Function(PieTouchedSection?)? onChartSectionTouched;
  final double? centerSpaceRadius;
  final double sectionsSpace;

  StandardPieChart({
    Key? key,
    required this.sections,
    this.sectionsSpace = 0.0,
    this.centerSpaceRadius,
    this.onChartSectionTouched,
  }) : super(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (event, pieTouchResponse) {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  onChartSectionTouched?.call(null);
                  return;
                }
                onChartSectionTouched?.call(
                  pieTouchResponse.touchedSection!,
                );
              },
            ),
            sectionsSpace: sectionsSpace,
            centerSpaceRadius: centerSpaceRadius,
            borderData: FlBorderData(
              show: false,
            ),
            sections: sections,
          ),
          key: key,
        );
}
