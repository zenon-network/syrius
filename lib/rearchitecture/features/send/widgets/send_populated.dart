import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/send/send.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SendPopulated extends StatefulWidget {
  const SendPopulated({
    required this.balances,
    super.key,
  });

  /// A map with wallet addresses as keys, and account info objects as values
  final Map<String, AccountInfo> balances;

  @override
  State<SendPopulated> createState() => _SendPopulatedState();
}

class _SendPopulatedState extends State<SendPopulated> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final FocusNode _recipientFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();

  final GlobalKey<LoadingButtonState> _sendPaymentButtonKey = GlobalKey();

  final List<Token> _tokensWithBalance = <Token>[];

  Token _selectedToken = kDualCoin.first;

  String _selectedSelfAddress = kSelectedAddress!;

  String get _amount => _amountController.text;

  String get _recipient => _recipientController.text;

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

    String? recipientErrorText;

    String? amountErrorText;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _recipientController,
            builder: (_, TextEditingValue recipient, __) {
              recipientErrorText = _recipient.isNotEmpty
                  ? InputValidators.checkAddress(_recipient)
                  : null;

              return TextField(
                controller: _recipientController,
                decoration: InputDecoration(
                  errorText: recipientErrorText,
                  hintText: context.l10n.recipientAddress,
                  suffixIcon: IconButton(
                    onPressed: () {
                      ClipboardUtils.pasteToClipboard(context, (String value) {
                        _recipientController.text = value;
                      });
                    },
                    icon: const Icon(
                      Icons.content_paste,
                    ),
                  ),
                ),
                focusNode: _recipientFocusNode,
                onSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_amountFocusNode);
                },
              );
            },
          ),
          kVerticalGap16,
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _amountController,
            builder: (_, TextEditingValue amount, __) {
              amountErrorText = _amountController.text.isNotEmpty
                  ? InputValidators.correctValue(
                      _amountController.text,
                      accountInfo.getBalance(
                        _selectedToken.tokenStandard,
                      ),
                      _selectedToken.decimals,
                      BigInt.zero,
                    )
                  : null;

              return TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  errorText: amountErrorText,
                  hintText: context.l10n.amount,
                  suffixIcon: TextButton(
                    onPressed: () => _onMaxPressed(accountInfo),
                    child: Text(context.l10n.max.toUpperCase()),
                  ),
                ),
                focusNode: _amountFocusNode,
                inputFormatters: FormatUtils.getAmountTextInputFormatters(
                  _amountController.text,
                ),
              );
            },
          ),
          kVerticalGap16,
          Center(
            child: ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[
                _amountController,
                _recipientController,
              ]),
              builder: (_, __) {
                final bool isInputValid = recipientErrorText == null &&
                    amountErrorText == null &&
                    _amountController.text.isNotEmpty &&
                    _recipient.isNotEmpty;

                return _getSendPaymentViewModel(
                  accountInfo: accountInfo,
                  isInputValid: isInputValid,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSendPaymentPressed() {
    showDialogWithNoAndYesOptions(
      isBarrierDismissible: false,
      context: context,
      title: context.l10n.send,
      description: '${context.l10n.areYouSureTranfer} '
          '${_amountController.text} ${_selectedToken.symbol} '
          '${context.l10n.to} '
          '${ZenonAddressUtils.getLabel(_recipient)} ?',
      onYesButtonPressed: _sendPayment,
    );
  }

  void _sendPayment() {
    context.read<SendTransactionBloc>().add(
          SendTransactionInitiate(
            fromAddress: _selectedSelfAddress,
            toAddress: _recipient,
            amount: _amount.extractDecimals(_selectedToken.decimals),
            token: _selectedToken,
          ),
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
      selectedAddress: _selectedSelfAddress,
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

    if (_amount.isEmpty ||
        _amount.extractDecimals(_selectedToken.decimals) < maxBalance) {
      _amountController.text = maxBalance.addDecimals(_selectedToken.decimals);
    }
  }

  Widget _getSendPaymentViewModel({
    required AccountInfo accountInfo,
    required bool isInputValid,
  }) {
    return BlocListener<SendTransactionBloc, SendTransactionState>(
      listener: (_, SendTransactionState state) {
        if (state.status == SendPaymentStatus.loading) {
          _sendPaymentButtonKey.currentState?.animateForward();
        } else if (state.status == SendPaymentStatus.success) {
          _sendConfirmationNotification();
          _sendPaymentButtonKey.currentState?.animateReverse();
          _amountController.clear();
          _recipientController.clear();
        } else if (state.status == SendPaymentStatus.failure) {
          _sendPaymentButtonKey.currentState?.animateReverse();
          _sendErrorNotification(state.error);
        }
      },
      child: SendButton(
        key: _sendPaymentButtonKey,
        text: context.l10n.send,
        onPressed: _hasBalance(accountInfo) && isInputValid
            ? _onSendPaymentPressed
            : null,
      ),
    );
  }

  Future<void> _sendErrorNotification(error) async {
    await NotificationUtils.sendNotificationError(
      error,
      '${context.l10n.couldNotSend} $_amount '
      '${_selectedToken.symbol} '
      '${context.l10n.to} $_recipient',
    );
  }

  Future<void> _sendConfirmationNotification() async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: '${context.l10n.sent} $_amount '
                '${_selectedToken.symbol} '
                '${context.l10n.to} '
                '${ZenonAddressUtils.getLabel(_recipient)}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: '${context.l10n.sent} '
                '$_amount ${_selectedToken.symbol} '
                '${context.l10n.from} '
                '${ZenonAddressUtils.getLabel(_selectedSelfAddress)} '
                '${context.l10n.to} '
                '${ZenonAddressUtils.getLabel(_recipient)}',
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

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
