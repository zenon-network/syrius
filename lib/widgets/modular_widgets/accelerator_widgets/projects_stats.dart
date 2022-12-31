import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ProjectsStats extends StatelessWidget {
  final Project project;

  const ProjectsStats(this.project, {Key? key}) : super(key: key);

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
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  AcceleratorProjectDetails(
                    owner: project.owner,
                    hash: project.id,
                    creationTimestamp: null,
                  ),
                ],
              ),
            ],
          ),
          kVerticalSpacing,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Visibility(
                child: Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _getChart(_getZnnChartSections(context)),
                      ),
                      const SizedBox(
                        width: 15.0,
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
                    children: [
                      Expanded(
                        flex: 2,
                        child: _getChart(_getQsrChartSections(context)),
                      ),
                      const SizedBox(
                        width: 15.0,
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
        maxWidth: 150.0,
        maxHeight: 150.0,
      ),
      child: AspectRatio(
        aspectRatio: 1.0,
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
      radius: 7.0,
      color: color,
      value: value,
    );
  }

  List<PieChartSectionData> _getZnnChartSections(BuildContext context) {
    return [
      _getBalanceChartSection(
        AppColors.znnColor,
        project.znnFundsNeeded == 0
            ? 1
            : project.getPaidZnnFunds() / project.znnFundsNeeded,
      ),
      _getBalanceChartSection(
        AppColors.znnColor.withOpacity(0.2),
        project.znnFundsNeeded == 0
            ? 0
            : project.getRemainingZnnFunds() / project.znnFundsNeeded,
      ),
    ];
  }

  List<PieChartSectionData> _getQsrChartSections(BuildContext context) {
    return [
      _getBalanceChartSection(
        AppColors.qsrColor,
        project.qsrFundsNeeded == 0
            ? 1
            : project.getPaidQsrFunds() / project.qsrFundsNeeded,
      ),
      _getBalanceChartSection(
        AppColors.qsrColor.withOpacity(0.5),
        project.qsrFundsNeeded == 0
            ? 0
            : project.getRemainingQsrFunds() / project.qsrFundsNeeded,
      ),
    ];
  }

  Widget _getProjectStats(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        child,
      ],
    );
  }

  Widget _getZnnProjectLegends(BuildContext context) {
    return SizedBox(
      height: 100.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartLegend(
            dotColor: AppColors.znnColor,
            mainText: 'Received funds',
            detailsWidget: FormattedAmountWithTooltip(
              amount: AmountUtils.addDecimals(
                  project.getPaidZnnFunds(), znnDecimals),
              tokenSymbol: kZnnCoin.symbol,
              builder: (amount, tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.znnColor.withOpacity(0.2),
            mainText: 'Remaining funds',
            detailsWidget: FormattedAmountWithTooltip(
              amount: AmountUtils.addDecimals(
                  project.getRemainingZnnFunds(), znnDecimals),
              tokenSymbol: kZnnCoin.symbol,
              builder: (amount, tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.znnColor.withOpacity(0.4),
            mainText: 'Total project cost',
            detailsWidget: FormattedAmountWithTooltip(
              amount: AmountUtils.addDecimals(
                  project.getTotalZnnFunds(), znnDecimals),
              tokenSymbol: kZnnCoin.symbol,
              builder: (amount, tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getQsrProjectLegends(BuildContext context) {
    return SizedBox(
      height: 100.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartLegend(
            dotColor: AppColors.qsrColor,
            mainText: 'Received funds',
            detailsWidget: FormattedAmountWithTooltip(
              amount: AmountUtils.addDecimals(
                  project.getPaidQsrFunds(), qsrDecimals),
              tokenSymbol: kQsrCoin.symbol,
              builder: (amount, tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.qsrColor.withOpacity(0.2),
            mainText: 'Remaining funds',
            detailsWidget: FormattedAmountWithTooltip(
              amount: AmountUtils.addDecimals(
                  project.getRemainingQsrFunds(), qsrDecimals),
              tokenSymbol: kQsrCoin.symbol,
              builder: (amount, tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ),
          ChartLegend(
            dotColor: AppColors.qsrColor.withOpacity(0.4),
            mainText: 'Total project cost',
            detailsWidget: FormattedAmountWithTooltip(
              amount: AmountUtils.addDecimals(
                  project.getTotalQsrFunds(), qsrDecimals),
              tokenSymbol: kQsrCoin.symbol,
              builder: (amount, tokenSymbol) => Text(
                '$amount $tokenSymbol',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
