import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/chart/standard_pie_chart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Takes in a list of [Token] and shows a chart with sections corresponding to
/// the total supply of each [Token].
///
/// When the cursor hovers over a section, that respective section is
/// highlighted
class DualCoinStatsChart extends StatelessWidget {

  /// Create a DualCoinStatsChart
  const DualCoinStatsChart({
    required this.tokenList,
    required this.touchedSectionIndexNotifier,
    super.key,
  });

  /// List of [Token] that will provide data for the chart
  final List<Token> tokenList;
  /// ValueNotifier used for rebuilding the widget tree when a section of the
  /// chart is being hovered over
  final ValueNotifier<int?> touchedSectionIndexNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: touchedSectionIndexNotifier,
      builder: (_, int? index, ___) => AspectRatio(
        aspectRatio: 1,
        child: StandardPieChart(
          sectionsSpace: 4,
          centerSpaceRadius: 0,
          sections: _showingSections(
            context: context,
            tokenList: tokenList,
            touchedSectionIndex: index,
          ),
          onChartSectionTouched: (PieTouchedSection? pieTouchedSection) {
            touchedSectionIndexNotifier.value =
                pieTouchedSection?.touchedSectionIndex;
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections({
    required BuildContext context,
    required List<Token> tokenList,
    required int? touchedSectionIndex,
  }) {
    final BigInt totalSupply = tokenList.fold<BigInt>(
      BigInt.zero,
      (BigInt previousValue, Token element) => previousValue + element.totalSupply,
    );
    return List.generate(
      tokenList.length,
      (int i) {
        final Token currentTokenInfo = tokenList[i];
        final bool isTouched = i == touchedSectionIndex;
        final double opacity = isTouched ? 1.0 : 0.5;
        return PieChartSectionData(
          color: ColorUtils.getTokenColor(currentTokenInfo.tokenStandard)
              .withOpacity(opacity),
          value: currentTokenInfo.totalSupply / totalSupply,
          title: currentTokenInfo.symbol,
          radius: 60,
          titleStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Colors.white,
              ),
        );
      },
    );
  }
}
