import 'package:flutter/material.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TokenBalance extends StatefulWidget {
  const TokenBalance({super.key});

  @override
  State createState() {
    return _TokenBalanceState();
  }
}

class _TokenBalanceState extends State<TokenBalance> {
  List<BalanceInfoListItem> _newTokenIds = <BalanceInfoListItem>[];

  @override
  void initState() {
    super.initState();
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
  }

  void _initNewTokens(AccountInfo accountInfo) {
    if (_newTokenIds.isNotEmpty) {
      _newTokenIds.clear();
    }
    _newTokenIds = accountInfo.balanceInfoList!.fold(
      <BalanceInfoListItem>[],
      (List<BalanceInfoListItem> previousValue, BalanceInfoListItem element) {
        if (!<TokenStandard>[kZnnCoin.tokenStandard, kQsrCoin.tokenStandard]
            .contains(element.token!.tokenStandard)) {
          previousValue.add(element);
        }
        return previousValue;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Token Balance',
      description: 'This card displays information about ZTS tokens that you '
          'currently hold in your wallet',
      childBuilder: () => StreamBuilder<Map<String, AccountInfo>?>(
        stream: sl.get<BalanceBloc>().stream,
        builder: (_, AsyncSnapshot<Map<String, AccountInfo>?> snapshot) {
          if (snapshot.hasError) {
            return SyriusErrorWidget(snapshot.error!);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              _initNewTokens(snapshot.data![kSelectedAddress!]!);
              if (_newTokenIds.isEmpty) {
                return const SyriusErrorWidget('No ZTS tokens available');
              }
              return _getWidgetBody(
                snapshot.data![kSelectedAddress!],
              );
            }
            return const SyriusLoadingWidget();
          }
          return const SyriusLoadingWidget();
        },
      ),
    );
  }

  Widget _getWidgetBody(AccountInfo? accountInfo) {
    return Column(
      children: <Widget>[
        kVerticalSpacing,
        Expanded(child: _getNewTokensGridViewStatus(accountInfo)),
      ],
    );
  }

  Widget _getTokenStatus(String formattedAmount, String tokenSymbol) {
    return Row(
      children: <Widget>[
        Text(
          '$formattedAmount $tokenSymbol',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _getNewTokensGridViewStatus(accountInfo) {
    return GridView.builder(
      itemCount: _newTokenIds.length,
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 100 / 20,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (BuildContext context, int index) => Padding(
        padding: const EdgeInsets.all(8),
        child: Marquee(
          child: FormattedAmountWithTooltip(
            amount: _newTokenIds[index]
                .balance!
                .addDecimals(_newTokenIds[index].token!.decimals),
            tokenSymbol: _newTokenIds[index].token!.symbol,
            builder: (String amount, String symbol) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '● ',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: ColorUtils.getTokenColor(
                            _newTokenIds[index].token!.tokenStandard,),
                      ),
                ),
                _getTokenStatus(amount, symbol),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
