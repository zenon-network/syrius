import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_stats/accelerator_stats.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the available ZNN and QSR balance of the Accelerator treasury.
class AcceleratorStatsCard extends StatelessWidget {
  /// Creates an [AcceleratorStatsCard].
  const AcceleratorStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _View();
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return BlocRefreshLoadingBuilder<
      AcceleratorBalanceBloc,
      AcceleratorBalanceState
    >(
      isLoading: (AcceleratorBalanceState state) =>
          state is AcceleratorBalanceLoading,
      builder: (BuildContext context, ValueListenable<bool> isRefreshLoading) {
        return NewCardScaffold(
          data: _buildCardData(context),
          isRefreshLoading: isRefreshLoading,
          onRefreshPressed: () {
            context.read<AcceleratorBalanceBloc>().add(
              const AcceleratorBalanceRequested(),
            );
          },
          body: BlocBuilder<AcceleratorBalanceBloc, AcceleratorBalanceState>(
            builder: (BuildContext context, AcceleratorBalanceState state) {
              return switch (state) {
                AcceleratorBalanceInitial() ||
                AcceleratorBalanceLoading() => const SyriusLoadingWidget(),
                AcceleratorBalanceFailure(:final SyriusException exception) =>
                  SyriusErrorWidget(
                    exception is AcceleratorFundEmptyException
                        ? context.l10n.acceleratorFundEmpty
                        : exception,
                  ),
                AcceleratorBalancePopulated(:final AccountInfo accountInfo) =>
                  _Populated(accountInfo: accountInfo),
              };
            },
          ),
        );
      },
    );
  }

  CardData _buildCardData(BuildContext context) => CardData(
    title: context.l10n.acceleratorStats,
    description: context.l10n.acceleratorAvailableBalance,
  );
}

class _Populated extends StatefulWidget {
  const _Populated({required this._accountInfo});

  final AccountInfo _accountInfo;

  @override
  State<_Populated> createState() => _PopulatedState();
}

class _PopulatedState extends State<_Populated> {
  String? _touchedSectionTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 150,
          child: _buildPieChart(context, widget._accountInfo),
        ),
        SizedBox(
          width: 200,
          child: _buildPieChartLegend(context, widget._accountInfo),
        ),
      ],
    );
  }

  Widget _buildPieChartLegend(BuildContext context, AccountInfo accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ChartLegend(
          dotColor: AppColors.znnColor,
          mainText: context.l10n.available,
          detailsWidget: FormattedAmountWithTooltip(
            amount: accountInfo
                .getBalance(kZnnCoin.tokenStandard)
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
          mainText: context.l10n.available,
          detailsWidget: FormattedAmountWithTooltip(
            amount: accountInfo
                .getBalance(kQsrCoin.tokenStandard)
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

  Widget _buildPieChart(BuildContext context, AccountInfo accountInfo) {
    return AspectRatio(
      aspectRatio: 1,
      child: StandardPieChart(
        sections: _buildChartSections(context, accountInfo),
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

  List<PieChartSectionData> _buildChartSections(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
    return <PieChartSectionData>[
      if (accountInfo.findTokenByTokenStandard(kZnnCoin.tokenStandard) != null)
        _buildPieChartSectionData(context, kZnnCoin, accountInfo),
      if (accountInfo.findTokenByTokenStandard(kQsrCoin.tokenStandard) != null)
        _buildPieChartSectionData(context, kQsrCoin, accountInfo),
    ];
  }

  PieChartSectionData _buildPieChartSectionData(
    BuildContext context,
    Token token,
    AccountInfo accountInfo,
  ) {
    final BigInt znnBalance = accountInfo.znn() ?? BigInt.zero;
    final BigInt qsrBalance = accountInfo.qsr() ?? BigInt.zero;
    final BigInt value = token.tokenStandard == kZnnCoin.tokenStandard
        ? znnBalance
        : qsrBalance;
    final BigInt sumValues = znnBalance + qsrBalance;
    final double ratio = sumValues > BigInt.zero ? value / sumValues : 0;

    final bool isTouched = token.symbol == _touchedSectionTitle;
    final double opacity = isTouched ? 1.0 : 0.5;

    return PieChartSectionData(
      color: ColorUtils.getTokenColor(
        token.tokenStandard,
      ).withValues(alpha: opacity),
      value: ratio,
      title: accountInfo.findTokenByTokenStandard(token.tokenStandard)!.symbol,
      radius: 60,
      titleStyle: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
