import 'package:fl_chart/fl_chart.dart';

/// Standardized [PieChart] with optional touch interaction reporting.
class StandardPieChart extends PieChart {
  /// Creates a [StandardPieChart].
  StandardPieChart({
    required this.sections,
    super.key,
    this.sectionsSpace = 0.0,
    this.centerSpaceRadius,
    this.onChartSectionTouched,
  }) : super(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback:
                  (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
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
        );

  /// Sections rendered in the pie chart.
  final List<PieChartSectionData> sections;

  /// Callback invoked when the user interacts with a chart section.
  final void Function(PieTouchedSection?)? onChartSectionTouched;

  /// Radius of the empty center cutout.
  final double? centerSpaceRadius;

  /// Space between adjacent pie sections.
  final double sectionsSpace;
}
