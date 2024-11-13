import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/send/send.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';
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
    required this.balances,
    super.key,
  });

  /// A map with wallet addresses as keys, and account info objects as values
  final Map<String, AccountInfo> balances;

  @override
  State<SendLargeCard> createState() => _SendLargeCardState();
}

class _SendLargeCardState extends State<SendLargeCard> {
  TextEditingController _recipientController = TextEditingController();
  TextEditingController _amountController = TextEditingController();

  GlobalKey<FormState> _recipientKey = GlobalKey();
  GlobalKey<FormState> _amountKey = GlobalKey();

  final GlobalKey<LoadingButtonState> _sendPaymentButtonKey = GlobalKey();

  final List<Token> _tokensWithBalance = <Token>[];

  Token _selectedToken = kDualCoin.first;

  String _selectedSelfAddress = kSelectedAddress!;

  @override
  void initState() {
    super.initState();
    sl.get<TransferWidgetsBalanceBloc>().getBalanceForAllAddresses();
    _tokensWithBalance.addAll(kDualCoin);
  }

  @override
  Widget build(BuildContext context) {
    final AccountInfo accountInfo = widget.balances[_selectedSelfAddress]!;

    if (_tokensWithBalance.length == kDualCoin.length) {
      _addTokensWithBalance(widget.balances[_selectedSelfAddress]!);
    }

    return _getBody(context, accountInfo);
  }

  Widget _getBody(BuildContext context, AccountInfo accountInfo) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _getDefaultAddressDropdown(),
              ),
              kHorizontalGap8,
              Expanded(
                child: _getCoinDropdown(),
              ),
            ],
          ),
          kVerticalGap8,
          AvailableBalance(
            _selectedToken,
            accountInfo,
          ),
          kVerticalGap8,
          Form(
            key: _recipientKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: InputField(
              onChanged: (String value) {
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
              hintText: context.l10n.recipientAddress,
            ),
          ),
          kVerticalGap16,
          Form(
            key: _amountKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: InputField(
              onChanged: (String value) {
                setState(() {});
              },
              inputFormatters: FormatUtils.getAmountTextInputFormatters(
                _amountController.text,
              ),
              controller: _amountController,
              validator: (String? value) => InputValidators.correctValue(
                value,
                accountInfo.getBalance(
                  _selectedToken.tokenStandard,
                ),
                _selectedToken.decimals,
                BigInt.zero,
              ),
              suffixIcon: _getAmountSuffix(accountInfo),
              hintText: context.l10n.amount,
            ),
          ),
          kVerticalGap16,
          _getSendPaymentViewModel(accountInfo),
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
        title: context.l10n.send,
        description: '${context.l10n.areYouSureTranfer} '
            '${_amountController.text} ${_selectedToken.symbol} '
            '${context.l10n.to} '
            '${ZenonAddressUtils.getLabel(_recipientController.text)} ?',
        onYesButtonPressed: () => _sendPayment(model),
      );
    }
  }

  Widget _getAmountSuffix(AccountInfo accountInfo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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
    return NewAddressesDropdown(
      addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      onSelectedCallback: (String value) => setState(
        () {
          _selectedSelfAddress = value;
          _selectedToken = kDualCoin.first;
          _tokensWithBalance
            ..clear()
            ..addAll(kDualCoin);
          sl.get<TransferWidgetsBalanceBloc>().getBalanceForAllAddresses();
        },
      ),
      selectedAddress:       _selectedSelfAddress,
    );
  }

  Widget _getCoinDropdown() => ZtsDropdown(
        availableTokens: _tokensWithBalance,
        selectedToken: _selectedToken,
        onChangeCallback: (Token value) {
          if (_selectedToken != value) {
            setState(
              () {
                _selectedToken = value;
              },
            );
          }
        },
      );

  void _onMaxPressed(AccountInfo accountInfo) {
    final BigInt maxBalance = accountInfo.getBalance(
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
      onViewModelReady: (SendPaymentBloc model) {
        model.stream.listen(
          (AccountBlockTemplate? event) async {
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
      builder: (_, SendPaymentBloc model, __) => SendPaymentButton(
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
      '${context.l10n.couldNotSend} ${_amountController.text} '
      '${_selectedToken.symbol} '
      '${context.l10n.to} ${_recipientController.text}',
    );
  }

  Future<void> _sendConfirmationNotification() async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: '${context.l10n.sent} ${_amountController.text} '
                '${_selectedToken.symbol} '
                '${context.l10n.to} '
                '${ZenonAddressUtils.getLabel(_recipientController.text)}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: '${context.l10n.sent} '
                '${_amountController.text} ${_selectedToken.symbol} '
                '${context.l10n.from} '
                '${ZenonAddressUtils.getLabel(_selectedSelfAddress)} '
                '${context.l10n.to} '
                '${ZenonAddressUtils.getLabel(_recipientController.text)}',
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
    for (final BalanceInfoListItem balanceInfo
        in accountInfo.balanceInfoList!) {
      if (balanceInfo.balance! > BigInt.zero &&
          !_tokensWithBalance.contains(balanceInfo.token)) {
        _tokensWithBalance.add(balanceInfo.token!);
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
