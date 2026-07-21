import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _BackVersion {
  burn,
  mint,
  transferOwnership,
}

class TokenCard extends StatefulWidget {
  const TokenCard({
    required this._token,
    required this._favoritesCallback,
    super.key,
  });

  final Token _token;
  final VoidCallback _favoritesCallback;

  @override
  State<TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<TokenCard> {
  final GlobalKey<FlipCardState> _cardKey = GlobalKey<FlipCardState>();

  final FlipCardController _flipCardController = FlipCardController();

  _BackVersion _backOfCardVersion = _BackVersion.burn;

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      key: _cardKey,
      rotateSide: RotateSide.right,
      animationDuration: const Duration(milliseconds: 500),
      controller: _flipCardController,
      frontWidget: _getFrontOfCard(),
      backWidget: _getBackOfCard(),
    );
  }

  void _flipCard() {
    unawaited(_flipCardController.flipcard());
  }

  Widget _getBackOfCard() {
    return BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
      builder: (_, MultipleBalanceState state) => switch (state.status) {
        MultipleBalanceStatus.failure => SyriusErrorWidget(state.error!),
        MultipleBalanceStatus.initial => const SyriusLoadingWidget(),
        MultipleBalanceStatus.loading => const SyriusLoadingWidget(),
        MultipleBalanceStatus.success => _getBackVersionOfCard(state.data!),
      },
    );
  }

  Widget _getFrontOfCard() {
    return Card.filled(
      color: context.newThemeData.inputDecorationTheme.fillColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              spacing: kHorizontalGap8.width!,
              children: <Widget>[
                Text(
                  widget._token.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (kDefaultAddressList.contains(
                  widget._token.owner.toString(),
                ))
                  Tooltip(
                    message: context.l10n.ownZtsToken,
                    child: const Icon(
                      Icons.account_circle,
                      color: AppColors.znnColor,
                    ),
                  ),
                if (widget._token.isUtility)
                  Tooltip(
                    message: context.l10n.utilityToken,
                    child: const Icon(
                      Icons.settings,
                      color: AppColors.znnColor,
                    ),
                  ),
              ],
            ),
            Text(
              widget._token.symbol.toUpperCase(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ColorUtils.getTokenColor(widget._token.tokenStandard),
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            widget._token.tokenStandard.toString(),
                            style: context.textTheme.titleMedium?.copyWith(
                              color: AppColors.znnColor,
                            ),
                          ),
                          CopyToClipboardButton(
                            widget._token.tokenStandard.toString(),
                          ),
                        ],
                      ),
                      kHorizontalGap8,
                      Wrap(
                        children: <Widget>[
                          if (kSelectedAddress ==
                              widget._token.owner.toString())
                            _buildTokenOptionIconButton(
                              tooltip: context.l10n.transferTokenOwnership,
                              iconData: Icons.compare_arrows,
                              onPressed: _onTransferTokenIconPressed,
                              iconColor: AppColors.znnColor,
                            ),
                          if (widget._token.isMintable &&
                              widget._token.totalSupply <
                                  widget._token.maxSupply)
                            _buildTokenOptionIconButton(
                              tooltip: context.l10n.mintableToken,
                              onPressed:
                                  kSelectedAddress ==
                                      widget._token.owner.toString()
                                  ? () {
                                      _backOfCardVersion = _BackVersion.mint;
                                      _flipCard();
                                      _refreshBalanceBloc();
                                    }
                                  : null,
                              iconData: Icons.build,
                            ),
                          if (widget._token.isBurnable)
                            _buildTokenOptionIconButton(
                              tooltip: context.l10n.burnableToken,
                              onPressed:
                                  kDefaultAddressList.contains(
                                    widget._token.owner.toString(),
                                  )
                                  ? () {
                                      _backOfCardVersion = _BackVersion.burn;
                                      _flipCard();
                                      _refreshBalanceBloc();
                                    }
                                  : null,
                              iconData: Icons.whatshot,
                            ),
                          TokenFavorite(
                            token: widget._token,
                            callback: widget._favoritesCallback,
                          ),
                        ],
                      ),
                      kHorizontalGap8,
                      Text(
                        context.l10n.decimals(widget._token.decimals),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                _buildAnimatedChart(widget._token),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      kDefaultAddressList.contains(
                            widget._token.owner.toString(),
                          )
                          ? kAddressLabelMap[widget._token.owner.toString()]!
                          : widget._token.owner.toShortString(),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    CopyToClipboardButton(widget._token.owner.toString()),
                  ],
                ),
                IconButton(
                  onPressed: () =>
                      NavigationUtils.openUrl(widget._token.domain),
                  tooltip: context.l10n.visitDomain(widget._token.domain),
                  icon: const Icon(
                    Icons.open_in_new,
                    color: AppColors.znnColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenOptionIconButton({
    required String tooltip,
    required IconData iconData,
    Color? iconColor,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      mouseCursor: onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.znnColor,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        iconData,
        color: iconColor,
      ),
    );
  }

  Widget _buildAnimatedChart(Token token) {
    final BigInt totalSupply = token.totalSupply;

    final BigInt maxSupply = token.maxSupply;

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        SizedBox(
          height: 100,
          width: 100,
          child: StandardPieChart(
            sections: <PieChartSectionData>[
              PieChartSectionData(
                showTitle: false,
                radius: 5,
                value: totalSupply / maxSupply,
                color: ColorUtils.getTokenColor(widget._token.tokenStandard),
              ),
              PieChartSectionData(
                showTitle: false,
                radius: 5,
                value: (maxSupply - totalSupply) / maxSupply,
                color: Colors.white12,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 70,
          child: FormattedAmountWithTooltip(
            amount: totalSupply.addDecimals(token.decimals),
            tokenSymbol: token.symbol,
            builder: (String formattedAmount, String tokenSymbol) => Text(
              '$formattedAmount $tokenSymbol',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  void _onTransferTokenIconPressed() {
    setState(() {
      _backOfCardVersion = _BackVersion.transferOwnership;
      _flipCard();
    });
  }

  Widget _getBackVersionOfCard(Map<String, AccountInfo> balanceMap) {
    switch (_backOfCardVersion) {
      case _BackVersion.burn:
        return BurnTokenView(
          accountInfo: balanceMap[kSelectedAddress!]!,
          onBackPressed: _flipCard,
          token: widget._token,
        );
      case _BackVersion.mint:
        return MintTokenView(
          accountInfo: balanceMap[kSelectedAddress!]!,
          onBackPressed: _flipCard,
          token: widget._token,
        );
      case _BackVersion.transferOwnership:
        return TransferTokenView(
          onBackPressed: _flipCard,
          token: widget._token,
        );
    }
  }

  void _refreshBalanceBloc() {
    sl.get<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      ),
    );
  }
}
