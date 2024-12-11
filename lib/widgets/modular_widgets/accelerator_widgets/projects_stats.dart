import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ProjectsStats extends StatelessWidget {

  const ProjectsStats(this.project, {super.key});
  final Project project;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Project Stats',
      childBuilder: () => _getWidgetBody(context),
      description: 'Detailed information about your project',
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    project.name,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  AcceleratorProjectDetails(
                    owner: project.owner,
                    hash: project.id,
                    creationTimestamp: project.creationTimestamp,
                  ),
                ],
              ),
            ],
          ),
          kVerticalSpacing,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Visibility(
                child: Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: _getChart(_getZnnChartSections(context)),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        flex: 3,
                        child: _getProjectStats(_getZnnProjectLegends(context)),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                child: Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: _getChart(_getQsrChartSections(context)),
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        flex: 3,
                        child: _getProjectStats(_getQsrProjectLegends(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getChart(List<PieChartSectionData> sections) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 150,
        maxHeight: 150,
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: StandardPieChart(
          sections: sections,
        ),
      ),
    );
  }

  PieChartSectionData _getBalanceChartSection(
    Color color,
    double value,
  ) {
    return PieChartSectionData(
      showTitle: false,
      radius: 7,
      color: color,
      value: value,
    );
  }

  List<PieChartSectionData> _getZnnChartSections(BuildContext context) {
    return <PieChartSectionData>[
      _getBalanceChartSection(
        AppColors.znnColor,
        project.znnFundsNeeded == BigInt.zero
            ? 1
            : project.getPaidZnnFunds() / project.znnFundsNeeded,
      ),
      _getBalanceChartSection(
        AppColors.znnColor.withOpacity(0.2),
        project.znnFundsNeeded == BigInt.zero
            ? 0
            : project.getRemainingZnnFunds() / project.znnFundsNeeded,
      ),
    ];
  }

  List<PieChartSectionData> _getQsrChartSections(BuildContext context) {
    return <PieChartSectionData>[
      _getBalanceChartSection(
        AppColors.qsrColor,
        project.qsrFundsNeeded == BigInt.zero
            ? 1
            : project.getPaidQsrFunds() / project.qsrFundsNeeded,
      ),
      _getBalanceChartSection(
        AppColors.qsrColor.withOpacity(0.5),
        project.qsrFundsNeeded == BigInt.zero
            ? 0
            : project.getRemainingQsrFunds() / project.qsrFundsNeeded,
      ),
    ];
  }

  Widget _getProjectStats(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        child,
      ],
    );
  }

  Widget _getZnnProjectLegends(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ChartLegend(
            dotColor: AppColors.znnColor,
            mainText: 'Received',
            detailsWidget: FormattedAmountWithTooltip(
              amount: project.getPaidZnnFunds().addDecimals(coinDecimals),
              tokenSymbol: kZnnCoin.symbol,
              builder: (String amount, String tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.znnColor.withOpacity(0.2),
            mainText: 'Remaining',
            detailsWidget: FormattedAmountWithTooltip(
              amount: project.getRemainingZnnFunds().addDecimals(coinDecimals),
              tokenSymbol: kZnnCoin.symbol,
              builder: (String amount, String tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.znnColor.withOpacity(0.4),
            mainText: 'Total',
            detailsWidget: FormattedAmountWithTooltip(
              amount: project.getTotalZnnFunds().addDecimals(coinDecimals),
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

  Widget _getQsrProjectLegends(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ChartLegend(
            dotColor: AppColors.qsrColor,
            mainText: 'Received',
            detailsWidget: FormattedAmountWithTooltip(
              amount: project.getPaidQsrFunds().addDecimals(coinDecimals),
              tokenSymbol: kQsrCoin.symbol,
              builder: (String amount, String tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.qsrColor.withOpacity(0.2),
            mainText: 'Remaining',
            detailsWidget: FormattedAmountWithTooltip(
              amount: project.getRemainingQsrFunds().addDecimals(coinDecimals),
              tokenSymbol: kQsrCoin.symbol,
              builder: (String amount, String tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.qsrColor.withOpacity(0.4),
            mainText: 'Total',
            detailsWidget: FormattedAmountWithTooltip(
              amount: project.getTotalQsrFunds().addDecimals(coinDecimals),
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
