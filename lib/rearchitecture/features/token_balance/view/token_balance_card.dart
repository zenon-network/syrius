import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the ZTS token balances for the selected address.
class TokenBalanceCard extends StatelessWidget {
  /// Creates a new instance.
  const TokenBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () {
        sl.get<MultipleBalanceBloc>().add(
          MultipleBalanceFetch(
            addresses: kDefaultAddressList.map((String? e) => e!).toList(),
          ),
        );
      },
      body: BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
        builder: (_, MultipleBalanceState state) => switch (state.status) {
          MultipleBalanceStatus.failure => _Error(error: state.error!),
          MultipleBalanceStatus.initial => const _Empty(),
          MultipleBalanceStatus.loading => const _Loading(),
          MultipleBalanceStatus.success => _Populated(balances: state.data!),
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.tokenBalanceTitle,
    description: context.l10n.tokenBalanceDescription,
  );
}

class _Empty extends StatelessWidget {
  const _Empty({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(message ?? context.l10n.waitingForDataFetching);
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.error});

  final SyriusException error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}

class _Populated extends StatelessWidget {
  const _Populated({required this.balances});

  final Map<String, AccountInfo> balances;

  @override
  Widget build(BuildContext context) {
    final AccountInfo? accountInfo = balances[kSelectedAddress!];
    final List<BalanceInfoListItem> tokenBalances = _getTokenBalances(
      accountInfo,
    );

    if (tokenBalances.isEmpty) {
      return _Empty(message: context.l10n.noZtsTokensAvailable);
    }

    return Column(
      children: <Widget>[
        kVerticalSpacing,
        Expanded(child: _buildTokenBalancesGridView(tokenBalances)),
      ],
    );
  }

  List<BalanceInfoListItem> _getTokenBalances(AccountInfo? accountInfo) {
    return accountInfo?.balanceInfoList
            ?.where(
              (BalanceInfoListItem item) => !<TokenStandard>{
                kZnnCoin.tokenStandard,
                kQsrCoin.tokenStandard,
              }.contains(item.token!.tokenStandard),
            )
            .toList() ??
        <BalanceInfoListItem>[];
  }

  Widget _buildTokenBalancesGridView(
    List<BalanceInfoListItem> tokenBalances,
  ) {
    return GridView.builder(
      itemCount: tokenBalances.length,
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (BuildContext context, int index) =>
          FormattedAmountWithTooltip(
            amount: tokenBalances[index].balance!.addDecimals(
              tokenBalances[index].token!.decimals,
            ),
            tokenSymbol: tokenBalances[index].token!.symbol,
            builder: (String amount, String symbol) => RichText(
              text: TextSpan(
                text: amount,
                style: context.textTheme.bodyLarge,
                children: <InlineSpan>[
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: symbol,
                    style: TextStyle(
                      color: ColorUtils.getTokenColor(
                        tokenBalances[index].token!.tokenStandard,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
