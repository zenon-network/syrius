import 'package:auto_size_text/auto_size_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const String _kWidgetTitle = 'Balance';
final String _kWidgetDescription = 'This card displays the current '
    '${kZnnCoin.symbol} and ${kQsrCoin.symbol} amounts for the selected address';

class BalanceWidget extends StatefulWidget {
  const BalanceWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<BalanceWidget> createState() => _BalanceWidgetState();
}

class _BalanceWidgetState extends State<BalanceWidget> {
  String? _touchedTokenStandard;
  Color? _backgroundAddressColor;
  Color? _colorAddressPrefixSuffix;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorAddressPrefixSuffix ??= Theme.of(context).hintColor;
    _backgroundAddressColor ??= Theme.of(context).colorScheme.background;
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<BalanceDashboardBloc>.reactive(
      viewModelBuilder: () => BalanceDashboardBloc(),
      onViewModelReady: (model) {
        model.getDataPeriodically();
      },
      builder: (_, model, __) => CardScaffold<AccountInfo>(
        description: _kWidgetDescription,
        childStream: model.stream,
        onCompletedStatusCallback: (data) => _widgetBody(data),
        title: _kWidgetTitle,
      ),
    );
  }

  Widget _widgetBody(AccountInfo accountInfo) {
    return Column(
      children: [
        kVerticalSpacing,
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: StandardPieChart(
                    sectionsSpace: 0.0,
                    sections: _getChartSection(accountInfo),
                    onChartSectionTouched: (pieChartSection) {
                      setState(() {
                        _touchedTokenStandard =
                            pieChartSection?.touchedSection?.title;
                      });
                    }),
              ),
              _touchedTokenStandard != null
                  ? _getBalance(accountInfo)
                  : Container(),
            ],
          ),
        ),
        FocusableActionDetector(
          onShowHoverHighlight: (x) {
            if (x) {
              setState(() {
                _colorAddressPrefixSuffix = AppColors.znnColor;
              });
            } else {
              setState(() {
                _colorAddressPrefixSuffix = Theme.of(context).hintColor;
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: _backgroundAddressColor,
              border: Border.all(color: _backgroundAddressColor!),
              borderRadius: BorderRadius.circular(15.0),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 4.0,
              horizontal: 8.0,
            ),
            margin: const EdgeInsets.only(
              bottom: 12.0,
              top: 12.0,
            ),
            child: AutoSizeText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: kSelectedAddress!.substring(0, 3),
                    style: TextStyle(color: _colorAddressPrefixSuffix),
                  ),
                  TextSpan(
                    text: kSelectedAddress!.substring(
                      3,
                      kSelectedAddress!.length - 6,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  TextSpan(
                    text: kSelectedAddress!.substring(
                      kSelectedAddress!.length - 6,
                      kSelectedAddress!.length,
                    ),
                    style: TextStyle(
                      color: _colorAddressPrefixSuffix,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _getCoinBalanceInfo(kZnnCoin, accountInfo),
              ),
              Expanded(
                child: _getCoinBalanceInfo(kQsrCoin, accountInfo),
              ),
            ],
          ),
        ),
      ],
    );
  }

  FormattedAmountWithTooltip _getCoinBalanceInfo(
    Token coin,
    AccountInfo accountInfo,
  ) {
    return FormattedAmountWithTooltip(
      amount: accountInfo
          .getBalance(
            coin.tokenStandard,
          )
          .addDecimals(coin.decimals),
      tokenSymbol: coin.symbol,
      builder: (amount, tokenSymbol) => AmountInfoColumn(
        context: context,
        amount: amount,
        tokenSymbol: tokenSymbol,
      ),
    );
  }

  List<PieChartSectionData> _getChartSection(AccountInfo accountInfo) {
    List<PieChartSectionData> sections = [];
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

  Widget _getBalance(AccountInfo accountInfo) {
    TokenStandard tokenStandard = TokenStandard.parse(_touchedTokenStandard!);

    return SizedBox(
      width: 120.0,
      child: AutoSizeText(
        '${accountInfo.getBalance(
              tokenStandard,
            ).addDecimals(coinDecimals)} ${_touchedTokenStandard == kZnnCoin.tokenStandard.toString() ? kZnnCoin.symbol : kQsrCoin.symbol}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: ColorUtils.getTokenColor(tokenStandard),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  PieChartSectionData _getBalanceChartSection(
    Token token,
    AccountInfo accountInfo,
  ) {
    final isTouched = token.symbol == _touchedTokenStandard;
    final double opacity = isTouched ? 1.0 : 0.7;

    double value = accountInfo.getBalance(token.tokenStandard) /
        (accountInfo.znn()! + accountInfo.qsr()!);

    return PieChartSectionData(
      title: token.tokenStandard.toString(),
      showTitle: false,
      radius: 7.0,
      color: ColorUtils.getTokenColor(token.tokenStandard).withOpacity(opacity),
      value: value,
    );
  }
}
