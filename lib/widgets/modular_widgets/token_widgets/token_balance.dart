import 'package:flutter/material.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TokenBalance extends StatefulWidget {
  const TokenBalance({Key? key}) : super(key: key);

  @override
  State createState() {
    return _TokenBalanceState();
  }
}

class _TokenBalanceState extends State<TokenBalance> {
  List<BalanceInfoListItem> _newTokenIds = [];

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
      [],
      (previousValue, element) {
        if (![kZnnCoin.tokenStandard, kQsrCoin.tokenStandard]
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
        builder: (_, snapshot) {
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
      children: [
        kVerticalSpacing,
        Expanded(child: _getNewTokensGridViewStatus(accountInfo)),
      ],
    );
  }

  Widget _getTokenStatus(String formattedAmount, String tokenSymbol) {
    return Row(
      children: [
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
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
      ),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Marquee(
          child: FormattedAmountWithTooltip(
            amount: _newTokenIds[index]
                .balance!
                .addDecimals(_newTokenIds[index].token!.decimals),
            tokenSymbol: _newTokenIds[index].token!.symbol,
            builder: (amount, symbol) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '● ',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: ColorUtils.getTokenColor(
                            _newTokenIds[index].token!.tokenStandard),
                      ),
                ),
                _getTokenStatus(amount, symbol)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
