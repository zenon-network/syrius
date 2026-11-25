import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_projects/accelerator_projects.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays funding progress and metadata for a single Accelerator project.
class ProjectStatsCard extends StatelessWidget {
  /// Creates a [ProjectStatsCard].
  const ProjectStatsCard({required this._project, super.key});

  final Project _project;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context),
      body: _View(project: _project),
    );
  }

  CardData _buildCardData(BuildContext context) => CardData(
    title: context.l10n.projectStats,
    description: context.l10n.detailedInfoAboutYourProject,
  );
}

class _View extends StatelessWidget {
  const _View({required this._project});

  final Project _project;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_project.name),
                    const SizedBox(height: 5),
                    AcceleratorProjectMetadata(
                      owner: _project.owner,
                      hash: _project.id,
                      creationTimestamp: _project.creationTimestamp,
                    ),
                  ],
                ),
              ),
            ],
          ),
          kVerticalSpacing,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: _buildChart(_buildZnnChartSections()),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 3,
                      child: _buildStatsColumn(
                        _buildZnnProjectLegends(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: _buildChart(_buildQsrChartSections()),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 3,
                      child: _buildStatsColumn(
                        _buildQsrProjectLegends(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<PieChartSectionData> sections) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150, maxHeight: 150),
      child: AspectRatio(
        aspectRatio: 1,
        child: StandardPieChart(sections: sections),
      ),
    );
  }

  PieChartSectionData _buildBalanceChartSection(Color color, double value) {
    return PieChartSectionData(
      showTitle: false,
      radius: 7,
      color: color,
      value: value,
    );
  }

  List<PieChartSectionData> _buildZnnChartSections() {
    return <PieChartSectionData>[
      _buildBalanceChartSection(
        AppColors.znnColor,
        _project.znnFundsNeeded == BigInt.zero
            ? 1
            : _project.getPaidZnnFunds() / _project.znnFundsNeeded,
      ),
      _buildBalanceChartSection(
        AppColors.znnColor.withValues(alpha: 0.2),
        _project.znnFundsNeeded == BigInt.zero
            ? 0
            : _project.getRemainingZnnFunds() / _project.znnFundsNeeded,
      ),
    ];
  }

  List<PieChartSectionData> _buildQsrChartSections() {
    return <PieChartSectionData>[
      _buildBalanceChartSection(
        AppColors.qsrColor,
        _project.qsrFundsNeeded == BigInt.zero
            ? 1
            : _project.getPaidQsrFunds() / _project.qsrFundsNeeded,
      ),
      _buildBalanceChartSection(
        AppColors.qsrColor.withValues(alpha: 0.5),
        _project.qsrFundsNeeded == BigInt.zero
            ? 0
            : _project.getRemainingQsrFunds() / _project.qsrFundsNeeded,
      ),
    ];
  }

  Widget _buildStatsColumn(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[child],
    );
  }

  Widget _buildZnnProjectLegends(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ChartLegend(
            dotColor: AppColors.znnColor,
            mainText: context.l10n.received,
            detailsWidget: FormattedAmountWithTooltip(
              amount: _project.getPaidZnnFunds().addDecimals(coinDecimals),
              tokenSymbol: kZnnCoin.symbol,
              builder: (String amount, String tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.znnColor.withValues(alpha: 0.2),
            mainText: context.l10n.remaining,
            detailsWidget: FormattedAmountWithTooltip(
              amount: _project.getRemainingZnnFunds().addDecimals(coinDecimals),
              tokenSymbol: kZnnCoin.symbol,
              builder: (String amount, String tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.znnColor.withValues(alpha: 0.4),
            mainText: context.l10n.total,
            detailsWidget: FormattedAmountWithTooltip(
              amount: _project.getTotalZnnFunds().addDecimals(coinDecimals),
              tokenSymbol: kZnnCoin.symbol,
              builder: (String amount, String tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQsrProjectLegends(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ChartLegend(
            dotColor: AppColors.qsrColor,
            mainText: context.l10n.received,
            detailsWidget: FormattedAmountWithTooltip(
              amount: _project.getPaidQsrFunds().addDecimals(coinDecimals),
              tokenSymbol: kQsrCoin.symbol,
              builder: (String amount, String tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.qsrColor.withValues(alpha: 0.2),
            mainText: context.l10n.remaining,
            detailsWidget: FormattedAmountWithTooltip(
              amount: _project.getRemainingQsrFunds().addDecimals(coinDecimals),
              tokenSymbol: kQsrCoin.symbol,
              builder: (String amount, String tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.qsrColor.withValues(alpha: 0.4),
            mainText: context.l10n.total,
            detailsWidget: FormattedAmountWithTooltip(
              amount: _project.getTotalQsrFunds().addDecimals(coinDecimals),
              tokenSymbol: kQsrCoin.symbol,
              builder: (String amount, String tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
