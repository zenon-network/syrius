import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AcceleratorStats extends StatefulWidget {
  const AcceleratorStats({super.key});

  @override
  State<AcceleratorStats> createState() => _AcceleratorStatsState();
}

class _AcceleratorStatsState extends State<AcceleratorStats> {
  String? _touchedSectionTitle;

  @override
  void initState() {
    super.initState();
    sl.get<AcceleratorBalanceBloc>().getAcceleratorBalance();
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Accelerator Stats',
      childBuilder: () => _getWidgetBodyFutureBuilder(context),
      onRefreshPressed: () {
        sl.get<AcceleratorBalanceBloc>().getAcceleratorBalance();
      },
      description: 'Accelerator available balance',
    );
  }

  Widget _getWidgetBodyFutureBuilder(BuildContext context) {
    return StreamBuilder<AccountInfo?>(
      stream: sl.get<AcceleratorBalanceBloc>().stream,
      builder: (_, AsyncSnapshot<AccountInfo?> snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return _getWidgetBody(context, snapshot.data!);
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getWidgetBody(BuildContext context, AccountInfo accountInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 150,
          child: _getPieChart(accountInfo),
        ),
        SizedBox(
          width: 200,
          child: _getPieChartLegend(context, accountInfo),
        ),
      ],
    );
  }

  Widget _getPieChartLegend(BuildContext context, AccountInfo accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ChartLegend(
          dotColor: AppColors.znnColor,
          mainText: 'Available',
          detailsWidget: FormattedAmountWithTooltip(
            amount: accountInfo
                .getBalance(
                  kZnnCoin.tokenStandard,
                )
                .addDecimals(coinDecimals),
            tokenSymbol: kZnnCoin.symbol,
            builder: (String amount, String tokenSymbol) => Text(
              '$amount $tokenSymbol',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        kVerticalSpacing,
        ChartLegend(
          dotColor: AppColors.qsrColor,
          mainText: 'Available',
          detailsWidget: FormattedAmountWithTooltip(
            amount: accountInfo
                .getBalance(
                  kQsrCoin.tokenStandard,
                )
                .addDecimals(coinDecimals),
            tokenSymbol: kQsrCoin.symbol,
            builder: (String amount, String tokenSymbol) => Text(
              '$amount $tokenSymbol',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _getPieChart(AccountInfo accountInfo) {
    return AspectRatio(
      aspectRatio: 1,
      child: StandardPieChart(
        sections: showingSections(accountInfo),
        centerSpaceRadius: 0,
        sectionsSpace: 4,
        onChartSectionTouched: (PieTouchedSection? pieTouchedSection) {
          setState(() {
            _touchedSectionTitle = pieTouchedSection?.touchedSection?.title;
          });
        },
      ),
    );
  }

  List<PieChartSectionData> showingSections(AccountInfo accountInfo) {
    return <PieChartSectionData>[
      if (accountInfo.findTokenByTokenStandard(kZnnCoin.tokenStandard) != null)
        _getPieCharSectionsData(kZnnCoin, accountInfo),
      if (accountInfo.findTokenByTokenStandard(kQsrCoin.tokenStandard) != null)
        _getPieCharSectionsData(kQsrCoin, accountInfo),
    ];
  }

  PieChartSectionData _getPieCharSectionsData(
    Token token,
    AccountInfo accountInfo,
  ) {
    final BigInt value = token.tokenStandard == kZnnCoin.tokenStandard
        ? accountInfo.znn()!
        : accountInfo.qsr()!;
    final BigInt sumValues = accountInfo.znn()! + accountInfo.qsr()!;

    final bool isTouched = token.symbol == _touchedSectionTitle;
    final double opacity = isTouched ? 1.0 : 0.5;

    return PieChartSectionData(
      color: ColorUtils.getTokenColor(token.tokenStandard).withOpacity(opacity),
      value: value / sumValues,
      title: accountInfo.findTokenByTokenStandard(token.tokenStandard)!.symbol,
      radius: 60,
      titleStyle: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
