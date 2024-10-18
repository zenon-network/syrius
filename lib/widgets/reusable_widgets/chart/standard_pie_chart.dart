import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StandardPieChart extends PieChart {

  StandardPieChart({
    required this.sections, Key? key,
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
                  pieTouchResponse.touchedSection,
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
  final List<PieChartSectionData> sections;
  final void Function(PieTouchedSection?)? onChartSectionTouched;
  final double? centerSpaceRadius;
  final double sectionsSpace;
}
