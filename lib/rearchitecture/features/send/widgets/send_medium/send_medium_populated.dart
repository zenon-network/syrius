import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
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

/// A widget that helps the user send a transaction
///
/// It has two [TextField]s, one for the recipient - a valid Zenon address -
/// and one for the amount to be send
///
/// Through the [CoinDropdown], the user can select the coin or token to be sent
class SendMediumPopulated extends StatefulWidget {
  ///
  const SendMediumPopulated({
    required this.balances,
    required this.onExpandClicked,
    super.key,
  });

  /// Callback called when the user wants to expand the widget
  final VoidCallback onExpandClicked;
  /// A map with wallet addresses as keys, and account info objects as values
  final Map<String, AccountInfo> balances;

  @override
  State<SendMediumPopulated> createState() => _SendMediumPopulatedState();
}

class _SendMediumPopulatedState extends State<SendMediumPopulated> {
  TextEditingController _recipientController = TextEditingController();
  TextEditingController _amountController = TextEditingController();

  GlobalKey<FormState> _recipientKey = GlobalKey();
  GlobalKey<FormState> _amountKey = GlobalKey();

  Token _selectedToken = kDualCoin.first;

  final List<Token?> _tokensWithBalance = <Token?>[];

  final FocusNode _recipientFocusNode = FocusNode();

  final GlobalKey<LoadingButtonState> _sendPaymentButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    sl.get<TransferWidgetsBalanceBloc>().getBalanceForAllAddresses();
    _tokensWithBalance.addAll(kDualCoin);
  }

  @override
  Widget build(BuildContext context) {
    if (_tokensWithBalance.length == kDualCoin.length) {
      _addTokensWithBalance(widget.balances[kSelectedAddress!]!);
    }

    final AccountInfo accountInfo = widget.balances[kSelectedAddress!]!;

    final String? recipientErrorText = _recipientController.text.isNotEmpty
        ? InputValidators.checkAddress(_recipientController.text)
        : null;

    final String? amountErrorText = _amountController.text.isNotEmpty
        ? InputValidators.correctValue(
            _amountController.text,
            accountInfo.getBalance(
              _selectedToken.tokenStandard,
            ),
            _selectedToken.decimals,
            BigInt.zero,
          )
        : null;

    final bool thereAreInputErrors =
        recipientErrorText != null && amountErrorText != null;

    return Container(
      margin: const EdgeInsets.all(16),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          ListenableBuilder(
            listenable: _recipientController,
            builder: (_, __) => TextField(
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
              controller: _recipientController,
            ),
          ),
          kVerticalGap16,
          ListenableBuilder(
            listenable: _amountController,
            builder: (_, __) {
              return TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  errorText: amountErrorText,
                  hintText: context.l10n.amount,
                  suffixIcon: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _getAmountSuffix(accountInfo),
                  ),
                ),
                inputFormatters: FormatUtils.getAmountTextInputFormatters(
                  _amountController.text,
                ),
              );
            },
          ),
          kVerticalGap16,
          SizedBox(
            height: kMinInteractiveDimension,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned(
                  right: 0,
                  child: TransferToggleCardSizeButton(
                    onPressed: widget.onExpandClicked,
                    iconData: Icons.navigate_next,
                  ),
                ),
                ListenableBuilder(
                  listenable: Listenable.merge(<Listenable>[
                    _amountController,
                    _recipientController,
                  ]),
                  builder: (_, __) {
                    return _getSendPaymentViewModel(accountInfo);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSendPaymentPressed(SendPaymentBloc model) {
    if (_recipientKey.currentState!.validate() &&
        _amountKey.currentState!.validate()) {
      showDialogWithNoAndYesOptions(
        context: context,
        isBarrierDismissible: true,
        title: context.l10n.send,
        description: '${context.l10n.areYouSureTranfer} '
            '${_amountController.text} ${_selectedToken.symbol} ${context.l10n.to} '
            '${ZenonAddressUtils.getLabel(_recipientController.text)} ?',
        onYesButtonPressed: () => _sendPayment(model),
      );
    }
  }

  void _sendPayment(SendPaymentBloc model) {
    _sendPaymentButtonKey.currentState?.animateForward();
    model.sendTransfer(
      fromAddress: kSelectedAddress,
      toAddress: _recipientController.text,
      amount: _amountController.text.extractDecimals(_selectedToken.decimals),
      token: _selectedToken,
    );
  }

  Widget _getAmountSuffix(AccountInfo accountInfo) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _getCoinDropdown(),
        const SizedBox(
          width: 5,
        ),
        AmountSuffixMaxWidget(
          onPressed: () => _onMaxPressed(accountInfo),
          context: context,
        ),
      ],
    );
  }

  Widget _getCoinDropdown() => CoinDropdown(
        _tokensWithBalance,
        _selectedToken,
        (Token? value) {
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
      fireOnViewModelReadyOnce: true,
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
        key: _sendPaymentButtonKey,
      ),
      viewModelBuilder: SendPaymentBloc.new,
    );
  }

  Future<void> _sendErrorNotification(error) async {
    await NotificationUtils.sendNotificationError(
      error,
      '${context.l10n.couldNotSend} ${_amountController.text} ${_selectedToken.symbol} '
      '${context.l10n.to} ${_recipientController.text}',
    );
  }

  Future<void> _sendConfirmationNotification() async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title:
                '${context.l10n.send} ${_amountController.text} ${_selectedToken.symbol} '
                '${context.l10n.to} ${ZenonAddressUtils.getLabel(_recipientController.text)}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details:
                '${context.l10n.sent} ${_amountController.text} ${_selectedToken.symbol} '
                '${context.l10n.from} '
                '${ZenonAddressUtils.getLabel(kSelectedAddress!)} '
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
