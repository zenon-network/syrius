import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/send/send.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
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

/// A widget with multiple [DropdownMenu] and [TextField] that allow the user
/// to select and input the information needed for sending a transaction
class SendPopulated extends StatefulWidget {
  /// Creates a new instance.
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

  final List<Token> _initialTokens = kDualCoin;

  final List<Token> _tokensWithBalance = <Token>[];

  // The two coins - ZNN and QSR - should always be in this list
  List<Token> get _availableTokens => <Token>[
    ..._initialTokens,
    ..._tokensWithBalance,
  ];

  Token _selectedToken = kDualCoin.first;

  String _selectedSenderAddress = kSelectedAddress!;

  // The amount as inputted by the user
  String get _amount => _amountController.text;

  String get _recipient => _recipientController.text;

  AccountInfo get _accountInfo => widget.balances[_selectedSenderAddress]!;

  String? get _recipientErrorText =>
      _recipient.isNotEmpty ? InputValidators.checkAddress(_recipient) : null;

  String? get _amountErrorText => _amountController.text.isNotEmpty
      ? InputValidators.correctValue(
          _amountController.text,
          _accountInfo.getBalance(
            _selectedToken.tokenStandard,
          ),
          _selectedToken.decimals,
          BigInt.zero,
        )
      : null;

  bool get _isInputValid =>
      _recipientErrorText == null &&
      _amountErrorText == null &&
      _amountController.text.isNotEmpty &&
      _recipient.isNotEmpty;

  bool get _isValidTransaction => _hasBalance(_accountInfo) && _isInputValid;

  @override
  Widget build(BuildContext context) {
    if (_availableTokens.length == _initialTokens.length) {
      _addTokensWithBalance(widget.balances[_selectedSenderAddress]!);
    }

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
          _sendErrorNotification(state.error!);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              _accountInfo,
            ),
            kVerticalGap8,
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _recipientController,
              builder: (_, TextEditingValue recipient, __) {
                return TextField(
                  controller: _recipientController,
                  decoration: InputDecoration(
                    errorText: _recipientErrorText,
                    hintText: context.l10n.recipientAddress,
                    suffixIcon: IconButton(
                      onPressed: () {
                        ClipboardUtils.pasteToClipboard(context,
                            (String value) {
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
                return TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    errorText: _amountErrorText,
                    hintText: context.l10n.amount,
                    suffixIcon: TextButton(
                      onPressed: () => _onMaxPressed(_accountInfo),
                      child: Text(context.l10n.max.toUpperCase()),
                    ),
                  ),
                  focusNode: _amountFocusNode,
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _amountController.text,
                  ),
                  onSubmitted: (String value) {
                    if (_isValidTransaction) {
                      _onSendPaymentPressed();
                    }
                  },
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
                  return SendButton(
                    key: _sendPaymentButtonKey,
                    text: context.l10n.send,
                    onPressed:
                        _isValidTransaction ? _onSendPaymentPressed : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSendPaymentPressed() {
    final String title = context.l10n.send;

    final String symbol = _selectedToken.symbol;

    final String recipient = ZenonAddressUtils.getLabel(_recipient);

    final String description = context.l10n.areYouSureTranfer(
      _amount,
      recipient,
      symbol,
    );

    showDialogWithNoAndYesOptions(
      isBarrierDismissible: false,
      context: context,
      title: title,
      description: description,
      onYesButtonPressed: _sendPayment,
    );
  }

  void _sendPayment() {
    context.read<SendTransactionBloc>().add(
          SendTransactionInitiate(
            amount: _amount.extractDecimals(_selectedToken.decimals),
            fromAddress: _selectedSenderAddress,
            toAddress: _recipient,
            token: _selectedToken,
          ),
        );
  }

  Widget _getDefaultAddressDropdown() {
    return NewAddressesDropdown(
      addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      onSelectedCallback: (String value) => setState(
        () {
          _selectedSenderAddress = value;
          _selectedToken = kDualCoin.first;
          _tokensWithBalance.clear();
        },
      ),
      selectedAddress: _selectedSenderAddress,
    );
  }

  Widget _getCoinDropdown() => ZtsDropdown(
        availableTokens: _availableTokens,
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

    final BigInt currentBalance = _amount.isEmpty
        ? BigInt.zero
        : _amount.extractDecimals(_selectedToken.decimals);

    if (currentBalance < maxBalance) {
      _amountController.text = maxBalance.addDecimals(_selectedToken.decimals);
    }
  }

  Future<void> _sendErrorNotification(SyriusException error) async {
    final String recipient = ZenonAddressUtils.getLabel(_recipient);

    final String symbol = _selectedToken.symbol;

    final String title = context.l10n.couldNotSend(_amount, recipient, symbol);

    await NotificationUtils.sendNotificationError(
      error,
      title,
    );
  }

  Future<void> _sendConfirmationNotification() async {
    final String recipient = ZenonAddressUtils.getLabel(_recipient);

    final String sender = ZenonAddressUtils.getLabel(_selectedSenderAddress);

    final String symbol = _selectedToken.symbol;

    final String title = context.l10n.sentDetails(
      _amount,
      recipient,
      sender,
      symbol,
    );

    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: title,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            // TODO(maznnwell): Add details - the hash, for example
            details: title,
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
    final List<BalanceInfoListItem> balanceInfoList =
        accountInfo.balanceInfoList!;

    for (final BalanceInfoListItem balanceInfo in balanceInfoList) {
      final BigInt balance = balanceInfo.balance!;
      final Token token = balanceInfo.token!;
      if (balance > BigInt.zero && !_initialTokens.contains(token)) {
        _tokensWithBalance.add(token);
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
