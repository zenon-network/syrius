import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
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

  Future<void> _flipCard() async {
    await _flipCardController.flipcard();
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

  Container _getFrontOfCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: context.newThemeData.inputDecorationTheme.fillColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 5,
                width: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorUtils.getTokenColor(widget._token.tokenStandard),
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              Tooltip(
                message: '${widget._token.name}: ${widget._token.symbol}',
                child: Text(
                  widget._token.symbol.toUpperCase(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(
                width: 5,
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Marquee(
                            child: Text(
                              widget._token.tokenStandard
                                  .toString()
                                  .toUpperCase(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        CopyToClipboardButton(
                          widget._token.tokenStandard.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Wrap(
                      children: <Widget>[
                        if (kDefaultAddressList.contains(
                          widget._token.owner.toString(),
                        ))
                          _getTokenOptionIconButton(
                            tooltip: context.l10n.ownZtsToken,
                            iconData: Icons.verified,
                            iconColor: AppColors.znnColor,
                          ),
                        if (kSelectedAddress == widget._token.owner.toString())
                          _getTokenOptionIconButton(
                            tooltip: context.l10n.transferTokenOwnership,
                            iconData: Icons.compare_arrows,
                            onPressed: _onTransferTokenIconPressed,
                            iconColor: AppColors.znnColor,
                          ),
                        if (widget._token.isMintable &&
                            widget._token.totalSupply < widget._token.maxSupply)
                          _getTokenOptionIconButton(
                            isOwner: kDefaultAddressList.contains(
                              widget._token.owner.toString(),
                            ),
                            tooltip: context.l10n.mintableToken,
                            onPressed:
                                kDefaultAddressList.contains(
                                  widget._token.owner.toString(),
                                )
                                ? () {
                                    _flipCard();
                                    _backOfCardVersion = _BackVersion.mint;
                                    _refreshBalanceBloc();
                                  }
                                : null,
                            iconData: Icons.build,
                          ),
                        if (widget._token.isBurnable)
                          _getTokenOptionIconButton(
                            isOwner: kDefaultAddressList.contains(
                              widget._token.owner.toString(),
                            ),
                            tooltip: context.l10n.burnableToken,
                            onPressed:
                                kDefaultAddressList.contains(
                                  widget._token.owner.toString(),
                                )
                                ? () {
                                    _flipCard();
                                    _backOfCardVersion = _BackVersion.burn;
                                    _refreshBalanceBloc();
                                  }
                                : null,
                            iconData: Icons.whatshot,
                          ),
                        if (widget._token.isUtility)
                          _getTokenOptionIconButton(
                            tooltip: context.l10n.utilityToken,
                            mouseCursor: SystemMouseCursors.basic,
                            iconData: Icons.settings,
                          ),
                        TokenFavorite(
                          widget._token,
                          widget._favoritesCallback,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      context.l10n.decimals(widget._token.decimals),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              _getAnimatedChart(widget._token),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    kDefaultAddressList.contains(widget._token.owner.toString())
                        ? kAddressLabelMap[widget._token.owner.toString()]!
                        : widget._token.owner.toShortString(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  CopyToClipboardButton(widget._token.owner.toString()),
                ],
              ),
              RawMaterialButton(
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const CircleBorder(),
                onPressed: () => NavigationUtils.openUrl(widget._token.domain),
                child: Tooltip(
                  message: context.l10n.visitDomain(widget._token.domain),
                  child: Container(
                    height: 25,
                    width: 25,
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white12,
                    ),
                    child: const Icon(
                      Icons.open_in_new,
                      size: 13,
                      color: AppColors.darkHintTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Material _getTokenOptionIconButton({
    required String tooltip,
    required IconData iconData,
    Color? iconColor,
    VoidCallback? onPressed,
    MouseCursor mouseCursor = SystemMouseCursors.click,
    bool? isOwner,
  }) {
    return Material(
      type: MaterialType.circle,
      shadowColor: Colors.transparent,
      color: Colors.transparent,
      child: IconButton(
        mouseCursor: isOwner != null
            ? isOwner
                  ? mouseCursor
                  : SystemMouseCursors.forbidden
            : mouseCursor,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        splashRadius: 18,
        onPressed: onPressed,
        iconSize: 25,
        icon: Icon(
          iconData,
          color: isOwner != null
              ? kDefaultAddressList.contains(widget._token.owner.toString())
                    ? AppColors.znnColor
                    : AppColors.lightSecondaryContainer
              : iconColor,
        ),
      ),
    );
  }

  Widget _getAnimatedChart(Token token) {
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
          child: Marquee(
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
