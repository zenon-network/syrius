import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
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
  final GlobalKey<FormState> _beneficiaryAddressKey = GlobalKey();
  final GlobalKey<FormState> _mintAmountKey = GlobalKey();
  GlobalKey<FormState> _newOwnerAddressKey = GlobalKey();

  final FlipCardController _flipCardController = FlipCardController();
  final TextEditingController _beneficiaryAddressController =
      TextEditingController();
  final TextEditingController _mintAmountController = TextEditingController();
  TextEditingController _newOwnerAddressController = TextEditingController();

  BigInt _mintMaxAmount = BigInt.zero;

  final GlobalKey<LoadingButtonState> _mintButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _transferButtonKey = GlobalKey();

  _BackVersion _backOfCardVersion = _BackVersion.burn;

  @override
  void initState() {
    super.initState();
    _beneficiaryAddressController.text = kSelectedAddress!;
  }

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
                            onPressed: _onTransferOwnershipIconPressed,
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

  Widget _buildMintAmountSuffix() {
    return Row(
      children: <Widget>[
        AmountSuffixMaxWidget(
          onPressed: _onMintMaxPressed,
          context: context,
        ),
      ],
    );
  }

  void _onMintMaxPressed() {
    final String maxAmount = _mintMaxAmount.addDecimals(
      widget._token.decimals,
    );
    if (_mintAmountController.text != maxAmount) {
      setState(() {
        _mintAmountController.text = maxAmount;
      });
    }
  }

  Widget _getMintBackOfCard(AccountInfo? accountInfo) {
    _mintMaxAmount = widget._token.maxSupply - widget._token.totalSupply;

    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        Form(
          key: _beneficiaryAddressKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            onChanged: (String value) {
              setState(() {});
            },
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp('[0-9a-z]')),
            ],
            controller: _beneficiaryAddressController,
            hintText: context.l10n.beneficiaryAddress,
            contentLeftPadding: 20,
            validator: InputValidators.checkAddress,
          ),
        ),
        StepperUtils.getBalanceWidget(widget._token, accountInfo!),
        Form(
          key: _mintAmountKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            onChanged: (String value) {
              setState(() {});
            },
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _mintAmountController.text,
            ),
            controller: _mintAmountController,
            validator: (String? value) => InputValidators.correctValue(
              value,
              _mintMaxAmount,
              widget._token.decimals,
              BigInt.zero,
            ),
            suffixIcon: _buildMintAmountSuffix(),
            suffixIconConstraints: const BoxConstraints(maxWidth: 50),
            hintText: context.l10n.amount,
            contentLeftPadding: 20,
          ),
        ),
        kVerticalSpacing,
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              children: <Widget>[
                _getMintButtonViewModel(),
                const SizedBox(
                  height: 10,
                ),
                StepperButton(
                  text: context.l10n.goBack,
                  onPressed: _flipCard,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _getMintButtonViewModel() {
    return ViewModelBuilder<MintTokenBloc>.reactive(
      onViewModelReady: (MintTokenBloc model) {
        model.stream.listen(
          (AccountBlockTemplate event) {
            setState(() {
              _beneficiaryAddressKey.currentState!.reset();
              _mintAmountKey.currentState!.reset();
              _mintAmountController.clear();
            });
            _mintButtonKey.currentState!.animateReverse();
            _sendMintSuccessfulNotification(event);
            _refreshBalanceBloc();
          },
          onError: (error) async {
            await NotificationUtils.sendNotificationError(
              error,
              context.l10n.errorMintingToken(widget._token.symbol),
            );
            _mintButtonKey.currentState!.animateReverse();
          },
        );
      },
      builder: (_, MintTokenBloc model, __) => _getMintButton(model),
      viewModelBuilder: MintTokenBloc.new,
    );
  }

  Future<void> _sendMintSuccessfulNotification(
    AccountBlockTemplate event,
  ) async {
    final String amount = event.amount.addDecimals(widget._token.decimals);

    await sl.get<NotificationsBloc>().addNotification(
      WalletNotification(
        title: context.l10n.successfullyMinted(
          amount,
          widget._token.symbol,
        ),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: context.l10n.successfullyMintedRequestedAmount(
          amount,
          event.hash,
          widget._token.symbol,
        ),
        type: NotificationType.paymentSent,
      ),
    );
  }

  Widget _getMintButton(MintTokenBloc model) {
    return LoadingButton.stepper(
      text: context.l10n.mint,
      onPressed:
          InputValidators.checkAddress(_beneficiaryAddressController.text) ==
                  null &&
              _mintMaxAmount > BigInt.zero &&
              _mintAmountController.text.isNotEmpty &&
              InputValidators.correctValue(
                    _mintAmountController.text,
                    _mintMaxAmount,
                    widget._token.decimals,
                    BigInt.zero,
                  ) ==
                  null
          ? () {
              _mintButtonKey.currentState!.animateForward();
              model.mintToken(
                widget._token,
                _mintAmountController.text.extractDecimals(
                  widget._token.decimals,
                ),
                Address.parse(_beneficiaryAddressController.text),
              );
            }
          : null,
      key: _mintButtonKey,
    );
  }

  void _onTransferOwnershipIconPressed() {
    setState(() {
      _backOfCardVersion = _BackVersion.transferOwnership;
      _flipCard();
    });
  }

  Widget _getTransferOwnershipBackOfCard() {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        Form(
          key: _newOwnerAddressKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            onChanged: (String value) {
              setState(() {});
            },
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp('[0-9a-z]')),
            ],
            controller: _newOwnerAddressController,
            hintText: context.l10n.newOwnerAddress,
            contentLeftPadding: 20,
            validator: InputValidators.checkAddress,
          ),
        ),
        kVerticalSpacing,
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              children: <Widget>[
                _getTransferOwnershipButtonViewModel(),
                const SizedBox(
                  height: 10,
                ),
                StepperButton(
                  text: context.l10n.goBack,
                  onPressed: _flipCard,
                ),
              ],
            ),
          ],
        ),
      ],
    );
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
        return _getMintBackOfCard(balanceMap[kSelectedAddress!]);
      case _BackVersion.transferOwnership:
        return _getTransferOwnershipBackOfCard();
    }
  }

  Widget _getTransferOwnershipButtonViewModel() {
    return ViewModelBuilder<TransferOwnershipBloc>.reactive(
      onViewModelReady: (TransferOwnershipBloc model) {
        model.stream.listen(
          (AccountBlockTemplate event) {
            _sendTransferSuccessfulNotification();
            if (mounted) {
              setState(() {
                _newOwnerAddressController = TextEditingController();
                _newOwnerAddressKey = GlobalKey();
              });
            }
            _transferButtonKey.currentState?.animateReverse();
          },
          onError: (error) async {
            _transferButtonKey.currentState?.animateReverse();
            await NotificationUtils.sendNotificationError(
              error,
              context.l10n.errorTransferringTokenOwnership,
            );
          },
        );
      },
      builder: (_, TransferOwnershipBloc model, __) => StreamBuilder(
        stream: model.stream,
        builder: (_, AsyncSnapshot<AccountBlockTemplate> snapshot) {
          if (snapshot.hasError) {
            return _getTransferOwnershipButton(model);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return _getTransferOwnershipButton(model);
            }
            return const SyriusLoadingWidget();
          }
          return _getTransferOwnershipButton(model);
        },
      ),
      viewModelBuilder: TransferOwnershipBloc.new,
    );
  }

  Future<void> _sendTransferSuccessfulNotification() async {
    await sl.get<NotificationsBloc>().addNotification(
      WalletNotification(
        title: context.l10n.transferredTokenOwnership(
          widget._token.name,
        ),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: context.l10n.transferredTokenOwnershipToAddress(
          _newOwnerAddressController.text,
          widget._token.name,
        ),
        type: NotificationType.paymentSent,
      ),
    );
  }

  Widget _getTransferOwnershipButton(TransferOwnershipBloc model) {
    return LoadingButton.stepper(
      text: context.l10n.transfer,
      onPressed:
          InputValidators.checkAddress(_newOwnerAddressController.text) == null
          ? () {
              _transferButtonKey.currentState!.animateForward();
              model.transferOwnership(
                widget._token.tokenStandard,
                Address.parse(_newOwnerAddressController.text),
                widget._token.isMintable,
                widget._token.isBurnable,
              );
            }
          : null,
      key: _transferButtonKey,
    );
  }

  void _refreshBalanceBloc() {
    sl.get<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _beneficiaryAddressController.dispose();
    _mintAmountController.dispose();
    _newOwnerAddressController.dispose();
    super.dispose();
  }
}
