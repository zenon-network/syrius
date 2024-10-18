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

  const BalanceChart({
    required this.accountInfo,
    required this.touchedSectionId,
    super.key,
  });
  final AccountInfo accountInfo;
  final ValueNotifier<String?> touchedSectionId;

  @override
  Widget build(BuildContext context) {
    return StandardPieChart(
      sections: _getChartSection(accountInfo),
      onChartSectionTouched: (pieChartSection) {
        touchedSectionId.value = pieChartSection?.touchedSection?.title;
      },
    );
  }

  List<PieChartSectionData> _getChartSection(AccountInfo accountInfo) {
    final sections = <PieChartSectionData>[];
    if (accountInfo.znn()! > BigInt.zero) {
      sections.add(
        _getBalanceChartSection(
          accountInfo.findTokenByTokenStandard(kZnnCoin.tokenStandard)!,
          accountInfo,
        ),
      );
    }
    if (accountInfo.qsr()! > BigInt.zero) {
      sections.add(
        _getBalanceChartSection(
          accountInfo.findTokenByTokenStandard(kQsrCoin.tokenStandard)!,
          accountInfo,
        ),
      );
    }

    return sections;
  }

  PieChartSectionData _getBalanceChartSection(
    Token token,
    AccountInfo accountInfo,
  ) {
    final isTouched =
        token.tokenStandard.toString() == touchedSectionId.value;
    final opacity = isTouched ? 1.0 : 0.7;

    final value = accountInfo.getBalance(token.tokenStandard) /
        (accountInfo.znn()! + accountInfo.qsr()!);

    return PieChartSectionData(
      title: token.tokenStandard.toString(),
      showTitle: false,
      radius: 7,
      color: ColorUtils.getTokenColor(token.tokenStandard).withOpacity(opacity),
      value: value,
    );
  }
}
