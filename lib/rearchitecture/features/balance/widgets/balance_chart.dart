import 'package:big_decimal/big_decimal.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/chart/standard_pie_chart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A customized [StandardPieChart] that shows the balance in ZNN and QSR hold
/// be the user on a certain address
///
/// Hovering over the sections of the chart will trigger the balance - in a
/// readable format - to appear in the center of the chart
class BalanceChart extends StatelessWidget {
  /// Creates a BalanceChart objects
  const BalanceChart({
    required this.accountInfo,
    required this.hoveredSectionId,
    required this.zts,
    super.key,
  });

  /// Data needed for the chart
  final AccountInfo accountInfo;

  /// Notifier that holds the id of the hovered chart section
  final ValueNotifier<String?> hoveredSectionId;

  /// Coins and tokens for which to show the legend
  final List<Token> zts;

  @override
  Widget build(BuildContext context) {
    return StandardPieChart(
      sections: _getChartSection(accountInfo),
      onChartSectionTouched: (PieTouchedSection? pieChartSection) {
        hoveredSectionId.value = pieChartSection?.touchedSection?.title;
      },
    );
  }

  List<PieChartSectionData> _getChartSection(AccountInfo accountInfo) {
    final List<BalanceInfoListItem> balances = _getTokenBalances(accountInfo);

    final List<PieChartSectionData> sections = <PieChartSectionData>[];

    final BigDecimal sum = _getTotalNormalizedBalance(balances: balances);

    for (final BalanceInfoListItem balance in balances) {
      sections.add(
        _getBalanceChartSection(
          balanceInfo: balance,
          sum: sum,
        ),
      );
    }

    return sections;
  }

  List<BalanceInfoListItem> _getTokenBalances(AccountInfo accountInfo) {
    final List<BalanceInfoListItem> balances =
        accountInfo.balanceInfoList
            ?.where(
              (BalanceInfoListItem item) => zts.contains(item.token),
            )
            .toList() ??
        <BalanceInfoListItem>[];

    return balances;
  }

  BigDecimal _getTotalNormalizedBalance({
    required List<BalanceInfoListItem> balances,
  }) {
    BigDecimal sum = BigDecimal.zero;

    for (final BalanceInfoListItem balance in balances) {
      sum += balance.normalizedBalance;
    }

    return sum;
  }

  PieChartSectionData _getBalanceChartSection({
    required BalanceInfoListItem balanceInfo,
    required BigDecimal sum,
  }) {
    final TokenStandard tokenStandard = balanceInfo.token!.tokenStandard;

    final bool isTouched = tokenStandard.toString() == hoveredSectionId.value;
    final double opacity = isTouched ? 1.0 : 0.7;

    final double value =
        balanceInfo.normalizedBalance.toDouble() / sum.toDouble();

    return PieChartSectionData(
      title: tokenStandard.toString(),
      showTitle: false,
      radius: 7,
      color: ColorUtils.getTokenColor(tokenStandard).withValues(
        alpha: opacity,
      ),
      value: value,
    );
  }
}

/// Provides token balance lookup helpers for [AccountInfo].
extension AccountInfoExtension on AccountInfo {
  /// Returns the balance information for [tokenStandard], when available.
  BalanceInfoListItem? getBalanceInfo({required TokenStandard tokenStandard}) =>
      balanceInfoList!.firstWhereOrNull(
        (BalanceInfoListItem element) =>
            element.token!.tokenStandard == tokenStandard,
      );
}

/// Extension used to enhance the class [BalanceInfoListItem]
extension BalanceInfoListItemExtension on BalanceInfoListItem {
  /// Gets the balance as '1.0000004'
  BigDecimal get normalizedBalance =>
      BigDecimal.fromBigInt(
        balance!,
      ).divide(
        BigDecimal.parse('10').pow(token!.decimals),
        roundingMode: RoundingMode.UP,
      );
}
