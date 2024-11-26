import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
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

enum TokenCardBackVersion {
  burn,
  mint,
  transferOwnership,
}

class TokenCard extends StatefulWidget {

  const TokenCard(
    this.token,
    this._favoritesCallback, {
    super.key,
  });
  final Token token;
  final VoidCallback _favoritesCallback;

  @override
  State<TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<TokenCard> {
  final GlobalKey<FlipCardState> _cardKey = GlobalKey<FlipCardState>();
  final GlobalKey<FormState> _beneficiaryAddressKey = GlobalKey();
  final GlobalKey<FormState> _burnAmountKey = GlobalKey();
  final GlobalKey<FormState> _mintAmountKey = GlobalKey();
  GlobalKey<FormState> _newOwnerAddressKey = GlobalKey();

  final FlipCardController _flipCardController = FlipCardController();
  final TextEditingController _beneficiaryAddressController =
      TextEditingController();
  final TextEditingController _burnAmountController = TextEditingController();
  final TextEditingController _mintAmountController = TextEditingController();
  TextEditingController _newOwnerAddressController = TextEditingController();

  BigInt _burnMaxAmount = BigInt.zero;
  BigInt _mintMaxAmount = BigInt.zero;

  final GlobalKey<LoadingButtonState> _burnButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _mintButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _transferButtonKey = GlobalKey();

  TokenCardBackVersion _backOfCardVersion = TokenCardBackVersion.burn;

  @override
  void initState() {
    super.initState();
    _beneficiaryAddressController.text = kSelectedAddress!;
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
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
    return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: StreamBuilder<Map<String, AccountInfo>?>(
          stream: sl.get<BalanceBloc>().stream,
          builder: (_, AsyncSnapshot<Map<String, AccountInfo>?> snapshot) {
            if (snapshot.hasError) {
              return SyriusErrorWidget(snapshot.error!);
            }
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                return _getBackVersionOfCard(snapshot.data!);
              }
              return const SyriusLoadingWidget();
            }
            return const SyriusLoadingWidget();
          },
        ),);
  }

  Container _getFrontOfCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.primaryContainer,
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
                  color: ColorUtils.getTokenColor(widget.token.tokenStandard),
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              Tooltip(
                message: '${widget.token.name}: ${widget.token.symbol}',
                child: Text(
                  widget.token.symbol.toUpperCase(),
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
                              widget.token.tokenStandard
                                  .toString()
                                  .toUpperCase(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        CopyToClipboardButton(
                          widget.token.tokenStandard.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Wrap(
                      children: <Widget>[
                        if (kDefaultAddressList
                            .contains(widget.token.owner.toString()))
                          _getTokenOptionIconButton(
                            tooltip: 'You own this ZTS token',
                            iconData: Icons.verified,
                            iconColor: AppColors.znnColor,
                          ),
                        if (kSelectedAddress == widget.token.owner.toString())
                          _getTokenOptionIconButton(
                            tooltip: 'Transfer token ownership',
                            iconData: Icons.compare_arrows,
                            onPressed: _onTransferOwnershipIconPressed,
                            iconColor: AppColors.znnColor,
                          ),
                        if (widget.token.isMintable &&
                            widget.token.totalSupply < widget.token.maxSupply)
                          _getTokenOptionIconButton(
                            isOwner: kDefaultAddressList
                                .contains(widget.token.owner.toString()),
                            tooltip: 'Mintable token',
                            onPressed: kDefaultAddressList
                                    .contains(widget.token.owner.toString())
                                ? () {
                                    _flipCard();
                                    _backOfCardVersion =
                                        TokenCardBackVersion.mint;
                                    sl
                                        .get<BalanceBloc>()
                                        .getBalanceForAllAddresses();
                                  }
                                : null,
                            iconData: Icons.build,
                          ),
                        if (widget.token.isBurnable)
                          _getTokenOptionIconButton(
                            isOwner: kDefaultAddressList
                                .contains(widget.token.owner.toString()),
                            tooltip: 'Burnable token',
                            onPressed: kDefaultAddressList.contains(
                              widget.token.owner.toString(),
                            )
                                ? () {
                                    _flipCard();
                                    _backOfCardVersion =
                                        TokenCardBackVersion.burn;
                                    sl
                                        .get<BalanceBloc>()
                                        .getBalanceForAllAddresses();
                                  }
                                : null,
                            iconData: Icons.whatshot,
                          ),
                        if (widget.token.isUtility)
                          _getTokenOptionIconButton(
                            tooltip: 'Utility token',
                            mouseCursor: SystemMouseCursors.basic,
                            iconData: Icons.settings,
                          ),
                        TokenFavorite(
                          widget.token,
                          widget._favoritesCallback,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '${widget.token.decimals} decimals',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              _getAnimatedChart(widget.token),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    kDefaultAddressList.contains(widget.token.owner.toString())
                        ? kAddressLabelMap[widget.token.owner.toString()]!
                        : widget.token.owner.toShortString(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  CopyToClipboardButton(widget.token.owner.toString()),
                ],
              ),
              RawMaterialButton(
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: const CircleBorder(),
                onPressed: () => NavigationUtils.openUrl(widget.token.domain),
                child: Tooltip(
                  message: 'Visit ${widget.token.domain}',
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
              ? kDefaultAddressList.contains(widget.token.owner.toString())
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
                color: ColorUtils.getTokenColor(widget.token.tokenStandard),
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

  Widget _getBurnBackOfCard(AccountInfo accountInfo) {
    _burnMaxAmount = accountInfo.getBalance(
      widget.token.tokenStandard,
    );

    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        Form(
          key: _burnAmountKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            onChanged: (String value) {
              setState(() {});
            },
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _burnAmountController.text,
            ),
            controller: _burnAmountController,
            validator: (String? value) => InputValidators.correctValue(
                value, _burnMaxAmount, widget.token.decimals, BigInt.zero,),
            suffixIcon: _getAmountSuffix(),
            suffixIconConstraints: const BoxConstraints(maxWidth: 50),
            hintText: 'Amount',
            contentLeftPadding: 20,
          ),
        ),
        StepperUtils.getBalanceWidget(widget.token, accountInfo),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              children: <Widget>[
                _getBurnButtonViewModel(),
                const SizedBox(
                  height: 10,
                ),
                StepperButton(
                  text: 'Go back',
                  onPressed: _flipCard,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _getBurnButtonViewModel() {
    return ViewModelBuilder<BurnTokenBloc>.reactive(
      onViewModelReady: (BurnTokenBloc model) {
        model.stream.listen(
          (AccountBlockTemplate event) {
            setState(() {
              _burnAmountKey.currentState?.reset();
              _burnAmountController.clear();
            });
            _burnButtonKey.currentState?.animateReverse();
            _sendBurnSuccessfulNotification(event);
            sl.get<BalanceBloc>().getBalanceForAllAddresses();
          },
          onError: (error) async {
            _burnButtonKey.currentState?.animateReverse();
            await NotificationUtils.sendNotificationError(
              error,
              'Error while trying to burn ZTS',
            );
          },
        );
      },
      builder: (_, BurnTokenBloc model, __) => _getBurnButton(model),
      viewModelBuilder: BurnTokenBloc.new,
    );
  }

  Future<void> _sendBurnSuccessfulNotification(
      AccountBlockTemplate event,) async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Successfully burned ${event.amount.addDecimals(
              widget.token.decimals,
            )} ${widget.token.symbol}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'You have successfully burned the requested amount: '
                '${event.amount.addDecimals(
              widget.token.decimals,
            )} ${widget.token.symbol} ${event.hash}',
            type: NotificationType.burnToken,
          ),
        );
  }

  Widget _getBurnButton(BurnTokenBloc model) {
    return LoadingButton.stepper(
      text: 'Burn',
      onPressed: _burnMaxAmount > BigInt.zero &&
              _burnAmountController.text.isNotEmpty &&
              InputValidators.correctValue(_burnAmountController.text,
                      _burnMaxAmount, widget.token.decimals, BigInt.zero,) ==
                  null
          ? () {
              _burnButtonKey.currentState?.animateForward();
              model.burnToken(
                  widget.token,
                  _burnAmountController.text
                      .extractDecimals(widget.token.decimals),);
            }
          : null,
      key: _burnButtonKey,
    );
  }

  Widget _getAmountSuffix() {
    return Row(
      children: <Widget>[
        AmountSuffixMaxWidget(
          onPressed: _onMaxPressed,
          context: context,
        ),
      ],
    );
  }

  void _onMaxPressed() {
    if (_burnAmountController.text.isEmpty ||
        _burnAmountController.text.extractDecimals(widget.token.decimals) !=
            _burnMaxAmount ||
        _burnAmountController.text.extractDecimals(widget.token.decimals) !=
            _mintMaxAmount) {
      setState(() {
        if (_backOfCardVersion == TokenCardBackVersion.burn) {
          _burnAmountController.text =
              _burnMaxAmount.addDecimals(widget.token.decimals);
        } else {
          _mintAmountController.text =
              _mintMaxAmount.addDecimals(widget.token.decimals);
        }
      });
    }
  }

  Widget _getMintBackOfCard(AccountInfo? accountInfo) {
    _mintMaxAmount = widget.token.maxSupply - widget.token.totalSupply;

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
            hintText: 'Beneficiary address',
            contentLeftPadding: 20,
            validator: InputValidators.checkAddress,
          ),
        ),
        StepperUtils.getBalanceWidget(widget.token, accountInfo!),
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
                value, _mintMaxAmount, widget.token.decimals, BigInt.zero,),
            suffixIcon: _getAmountSuffix(),
            suffixIconConstraints: const BoxConstraints(maxWidth: 50),
            hintText: 'Amount',
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
                  text: 'Go back',
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
        model.stream.listen((AccountBlockTemplate event) {
          setState(() {
            _beneficiaryAddressKey.currentState!.reset();
            _mintAmountKey.currentState!.reset();
            _mintAmountController.clear();
          });
          _mintButtonKey.currentState!.animateReverse();
          _sendMintSuccessfulNotification(event);
          sl.get<BalanceBloc>().getBalanceForAllAddresses();
        }, onError: (error) async {
          await NotificationUtils.sendNotificationError(
            error,
            'Error while trying to mint ${widget.token.symbol}}',
          );
          _mintButtonKey.currentState!.animateReverse();
        },);
      },
      builder: (_, MintTokenBloc model, __) => _getMintButton(model),
      viewModelBuilder: MintTokenBloc.new,
    );
  }

  Future<void> _sendMintSuccessfulNotification(
      AccountBlockTemplate event,) async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Successfully minted ${event.amount.addDecimals(
              widget.token.decimals,
            )} ${widget.token.symbol}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'You have successfully minted the requested amount: '
                '${event.amount.addDecimals(
              widget.token.decimals,
            )} ${widget.token.symbol} ${event.hash}',
            type: NotificationType.paymentSent,
          ),
        );
  }

  Widget _getMintButton(MintTokenBloc model) {
    return LoadingButton.stepper(
      text: 'Mint',
      onPressed:
          InputValidators.checkAddress(_beneficiaryAddressController.text) ==
                      null &&
                  _mintMaxAmount > BigInt.zero &&
                  _mintAmountController.text.isNotEmpty &&
                  InputValidators.correctValue(_mintAmountController.text,
                          _mintMaxAmount, widget.token.decimals, BigInt.zero,) ==
                      null
              ? () {
                  _mintButtonKey.currentState!.animateForward();
                  model.mintToken(
                    widget.token,
                    _mintAmountController.text
                        .extractDecimals(widget.token.decimals),
                    Address.parse(_beneficiaryAddressController.text),
                  );
                }
              : null,
      key: _mintButtonKey,
    );
  }

  void _onTransferOwnershipIconPressed() {
    setState(() {
      _backOfCardVersion = TokenCardBackVersion.transferOwnership;
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
            hintText: 'New owner address',
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
                  text: 'Go back',
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
      case TokenCardBackVersion.burn:
        return _getBurnBackOfCard(balanceMap[kSelectedAddress!]!);
      case TokenCardBackVersion.mint:
        return _getMintBackOfCard(balanceMap[kSelectedAddress!]);
      case TokenCardBackVersion.transferOwnership:
        return _getTransferOwnershipBackOfCard();
    }
  }

  Widget _getTransferOwnershipButtonViewModel() {
    return ViewModelBuilder<TransferOwnershipBloc>.reactive(
      onViewModelReady: (TransferOwnershipBloc model) {
        model.stream.listen((AccountBlockTemplate event) {
          _sendTransferSuccessfulNotification();
          if (mounted) {
            setState(() {
              _newOwnerAddressController = TextEditingController();
              _newOwnerAddressKey = GlobalKey();
            });
          }
          _transferButtonKey.currentState?.animateReverse();
        }, onError: (error) async {
          _transferButtonKey.currentState?.animateReverse();
          await NotificationUtils.sendNotificationError(
            error,
            'Error while trying to transfer token ownership',
          );
        },);
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
            title: 'Successfully transferred ownership of '
                '${widget.token.name} token',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'Successfully transferred ownership of '
                '${widget.token.name} token to address '
                '${_newOwnerAddressController.text}',
            type: NotificationType.paymentSent,
          ),
        );
  }

  Widget _getTransferOwnershipButton(TransferOwnershipBloc model) {
    return LoadingButton.stepper(
      text: 'Transfer',
      onPressed:
          InputValidators.checkAddress(_newOwnerAddressController.text) == null
              ? () {
                  _transferButtonKey.currentState!.animateForward();
                  model.transferOwnership(
                    widget.token.tokenStandard,
                    Address.parse(_newOwnerAddressController.text),
                    widget.token.isMintable,
                    widget.token.isBurnable,
                  );
                }
              : null,
      key: _transferButtonKey,
    );
  }

  @override
  void dispose() {
    _beneficiaryAddressController.dispose();
    _burnAmountController.dispose();
    _mintAmountController.dispose();
    _newOwnerAddressController.dispose();
    super.dispose();
  }
}
