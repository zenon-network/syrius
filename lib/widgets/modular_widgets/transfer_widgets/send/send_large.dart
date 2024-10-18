import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SendLargeCard extends StatefulWidget {

  const SendLargeCard({
    super.key,
    this.cardWidth,
    this.extendIcon,
    this.onCollapsePressed,
  });
  final double? cardWidth;
  final bool? extendIcon;
  final VoidCallback? onCollapsePressed;

  @override
  State<SendLargeCard> createState() => _SendLargeCardState();
}

class _SendLargeCardState extends State<SendLargeCard> {
  TextEditingController _recipientController = TextEditingController();
  TextEditingController _amountController = TextEditingController();

  GlobalKey<FormState> _recipientKey = GlobalKey();
  GlobalKey<FormState> _amountKey = GlobalKey();

  final GlobalKey<LoadingButtonState> _sendPaymentButtonKey = GlobalKey();

  final List<Token?> _tokensWithBalance = [];

  Token _selectedToken = kDualCoin.first;

  String? _selectedSelfAddress = kSelectedAddress;

  @override
  void initState() {
    super.initState();
    sl.get<TransferWidgetsBalanceBloc>().getBalanceForAllAddresses();
    _tokensWithBalance.addAll(kDualCoin);
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Send',
      titleFontSize: Theme.of(context).textTheme.headlineSmall!.fontSize,
      description: 'Manage sending funds',
      childBuilder: _getBalanceStreamBuilder,
    );
  }

  Widget _getBalanceStreamBuilder() {
    return StreamBuilder<Map<String, AccountInfo>?>(
      stream: sl.get<TransferWidgetsBalanceBloc>().stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            if (_tokensWithBalance.length == kDualCoin.length) {
              _addTokensWithBalance(snapshot.data![_selectedSelfAddress!]!);
            }
            return _getBody(
              context,
              snapshot.data![_selectedSelfAddress!]!,
            );
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getBody(BuildContext context, AccountInfo accountInfo) {
    return Container(
      margin: const EdgeInsets.only(
        left: 20,
        top: 20,
      ),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 20),
            child: Form(
              key: _recipientKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: InputField(
                onChanged: (value) {
                  setState(() {});
                },
                controller: _recipientController,
                validator: InputValidators.checkAddress,
                suffixIcon: RawMaterialButton(
                  shape: const CircleBorder(),
                  onPressed: () {
                    ClipboardUtils.pasteToClipboard(context, (String value) {
                      _recipientController.text = value;
                      setState(() {});
                    });
                  },
                  child: const Icon(
                    Icons.content_paste,
                    color: AppColors.darkHintTextColor,
                    size: 15,
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(
                  maxWidth: 45,
                  maxHeight: 20,
                ),
                hintText: 'Recipient Address',
              ),
            ),
          ),
          kVerticalSpacing,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                flex: 8,
                child: Container(
                  margin: const EdgeInsets.only(right: 20),
                  child: Form(
                    key: _amountKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: InputField(
                      onChanged: (value) {
                        setState(() {});
                      },
                      inputFormatters: FormatUtils.getAmountTextInputFormatters(
                        _amountController.text,
                      ),
                      controller: _amountController,
                      validator: (value) => InputValidators.correctValue(
                          value,
                          accountInfo.getBalance(
                            _selectedToken.tokenStandard,
                          ),
                          _selectedToken.decimals,
                          BigInt.zero,),
                      suffixIcon: _getAmountSuffix(accountInfo),
                      hintText: 'Amount',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              'Send from',
              style: Theme.of(context).inputDecorationTheme.hintStyle,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _getDefaultAddressDropdown(),
              ),
              Container(
                width: 10,
              ),
              _getSendPaymentViewModel(accountInfo),
              const SizedBox(
                width: 20,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 10,
                  top: 10,
                ),
                child: AvailableBalance(
                  _selectedToken,
                  accountInfo,
                ),
              ),
              Visibility(
                visible: widget.extendIcon!,
                child: TransferToggleCardSizeButton(
                  onPressed: widget.onCollapsePressed,
                  iconData: Icons.navigate_before,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onSendPaymentPressed(SendPaymentBloc model) {
    if (_recipientKey.currentState!.validate() &&
        _amountKey.currentState!.validate()) {
      showDialogWithNoAndYesOptions(
        isBarrierDismissible: false,
        context: context,
        title: 'Send',
        description: 'Are you sure you want to transfer '
            '${_amountController.text} ${_selectedToken.symbol} to '
            '${ZenonAddressUtils.getLabel(_recipientController.text)} ?',
        onYesButtonPressed: () => _sendPayment(model),
      );
    }
  }

  Widget _getAmountSuffix(AccountInfo accountInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _getCoinDropdown(),
        const SizedBox(
          width: 5,
        ),
        AmountSuffixMaxWidget(
          onPressed: () => _onMaxPressed(accountInfo),
          context: context,
        ),
        const SizedBox(
          width: 15,
        ),
      ],
    );
  }

  void _sendPayment(SendPaymentBloc model) {
    _sendPaymentButtonKey.currentState?.animateForward();
    model.sendTransfer(
      fromAddress: _selectedSelfAddress,
      toAddress: _recipientController.text,
      amount: _amountController.text.extractDecimals(_selectedToken.decimals),
      token: _selectedToken,
    );
  }

  Widget _getDefaultAddressDropdown() {
    return AddressesDropdown(
      _selectedSelfAddress,
      (value) => setState(
        () {
          _selectedSelfAddress = value;
          _selectedToken = kDualCoin.first;
          _tokensWithBalance.clear();
          _tokensWithBalance.addAll(kDualCoin);
          sl.get<TransferWidgetsBalanceBloc>().getBalanceForAllAddresses();
        },
      ),
    );
  }

  Widget _getCoinDropdown() => CoinDropdown(
        _tokensWithBalance,
        _selectedToken,
        (value) {
          if (_selectedToken != value) {
            setState(
              () {
                _selectedToken = value!;
              },
            );
          }
        },
      );

  void _onMaxPressed(AccountInfo accountInfo) {
    final maxBalance = accountInfo.getBalance(
      _selectedToken.tokenStandard,
    );

    if (_amountController.text.isEmpty ||
        _amountController.text.extractDecimals(_selectedToken.decimals) <
            maxBalance) {
      setState(() {
        _amountController.text =
            maxBalance.addDecimals(_selectedToken.decimals);
      });
    }
  }

  Widget _getSendPaymentViewModel(AccountInfo? accountInfo) {
    return ViewModelBuilder<SendPaymentBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) async {
            if (event is AccountBlockTemplate) {
              await _sendConfirmationNotification();
              setState(() {
                _sendPaymentButtonKey.currentState?.animateReverse();
                _amountController = TextEditingController();
                _recipientController = TextEditingController();
                _amountKey = GlobalKey();
                _recipientKey = GlobalKey();
              });
            }
          },
          onError: (error) async {
            _sendPaymentButtonKey.currentState?.animateReverse();
            await _sendErrorNotification(error);
          },
        );
      },
      builder: (_, model, __) => SendPaymentButton(
        onPressed: _hasBalance(accountInfo!) && _isInputValid(accountInfo)
            ? () => _onSendPaymentPressed(model)
            : null,
        minimumSize: const Size(50, 48),
        key: _sendPaymentButtonKey,
      ),
      viewModelBuilder: SendPaymentBloc.new,
    );
  }

  Future<void> _sendErrorNotification(error) async {
    await NotificationUtils.sendNotificationError(
      error,
      "Couldn't send ${_amountController.text} "
      '${_selectedToken.symbol} '
      'to ${_recipientController.text}',
    );
  }

  Future<void> _sendConfirmationNotification() async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Sent ${_amountController.text} ${_selectedToken.symbol} '
                'to ${ZenonAddressUtils.getLabel(_recipientController.text)}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'Sent ${_amountController.text} ${_selectedToken.symbol} '
                'from ${ZenonAddressUtils.getLabel(_selectedSelfAddress!)} to ${ZenonAddressUtils.getLabel(_recipientController.text)}',
            type: NotificationType.paymentSent,
          ),
        );
  }

  bool _hasBalance(AccountInfo accountInfo) =>
      accountInfo.getBalance(
        _selectedToken.tokenStandard,
      ) >
      BigInt.zero;

  void _addTokensWithBalance(AccountInfo accountInfo) {
    for (final balanceInfo in accountInfo.balanceInfoList!) {
      if (balanceInfo.balance! > BigInt.zero &&
          !_tokensWithBalance.contains(balanceInfo.token)) {
        _tokensWithBalance.add(balanceInfo.token);
      }
    }
  }

  bool _isInputValid(AccountInfo accountInfo) =>
      InputValidators.checkAddress(_recipientController.text) == null &&
      InputValidators.correctValue(
            _amountController.text,
            accountInfo.getBalance(
              _selectedToken.tokenStandard,
            ),
            _selectedToken.decimals,
            BigInt.one,
            canBeEqualToMin: true,
          ) ==
          null;

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
