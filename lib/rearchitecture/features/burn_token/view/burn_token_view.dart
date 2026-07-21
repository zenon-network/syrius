import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/burn_token/bloc/burn_token_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the form used to burn an amount of a ZTS token.
class BurnTokenView extends StatelessWidget {
  /// Creates a [BurnTokenView].
  const BurnTokenView({
    required this._accountInfo,
    required this._onBackPressed,
    required this._token,
    super.key,
  });

  final AccountInfo _accountInfo;
  final VoidCallback _onBackPressed;
  final Token _token;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BurnTokenBloc>(
      create: (_) => BurnTokenBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: _View(
        accountInfo: _accountInfo,
        onBackPressed: _onBackPressed,
        token: _token,
      ),
    );
  }
}

class _View extends StatefulWidget {
  const _View({
    required this._accountInfo,
    required this._onBackPressed,
    required this._token,
  });

  final AccountInfo _accountInfo;
  final VoidCallback _onBackPressed;
  final Token _token;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final GlobalKey<LoadingButtonState> _buttonKey = GlobalKey();
  final TextEditingController _amountController = TextEditingController();

  BigInt get _maxAmount => widget._accountInfo.getBalance(
    widget._token.tokenStandard,
  );

  String get _amount => _amountController.text;

  String? get _amountError => InputValidators.correctValue(
    _amount,
    _maxAmount,
    widget._token.decimals,
    BigInt.zero,
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<BurnTokenBloc, BurnTokenState>(
      listener: _onBurnTokenStateChanged,
      child: ListView(
        children: <Widget>[
          TextField(
            onChanged: (_) => setState(() {}),
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _amountController.text,
            ),
            controller: _amountController,
            decoration: InputDecoration(
              errorText: _amount.isEmpty ? null : _amountError,
              hintText: context.l10n.amount,
              suffixIcon: TextButton(
                onPressed: _onMaxPressed,
                child: Text(context.l10n.max.toUpperCase()),
              ),
            ),
          ),
          StepperUtils.getBalanceWidget(widget._token, widget._accountInfo),
          Column(
            children: <Widget>[
              _buildBurnButton(),
              kVerticalGap16,
              OutlinedButton(
                onPressed: widget._onBackPressed,
                child: Text(context.l10n.goBack),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBurnButton() {
    return LoadingButton.stepper(
      text: context.l10n.burn,
      onPressed: _amountError == null ? _burnToken : null,
      key: _buttonKey,
    );
  }

  void _burnToken() {
    context.read<BurnTokenBloc>().add(
      BurnTokenRequested(
        amount: _amountController.text.extractDecimals(
          widget._token.decimals,
        ),
        token: widget._token,
      ),
    );
  }

  void _onBurnTokenStateChanged(BuildContext context, BurnTokenState state) {
    if (state is BurnTokenLoading) {
      _buttonKey.currentState?.animateForward();
    } else if (state is BurnTokenDone) {
      _amountController.clear();
      _buttonKey.currentState?.animateReverse();
      unawaited(_sendSuccessfulNotification(state.accountBlock));
    } else if (state is BurnTokenFailure) {
      _buttonKey.currentState?.animateReverse();
      unawaited(
        NotificationUtils.sendNotificationError(
          state.exception,
          context.l10n.errorBurningZts,
        ),
      );
    }
  }

  void _onMaxPressed() {
    final String maxAmount = _maxAmount.addDecimals(widget._token.decimals);
    if (_amountController.text != maxAmount) {
      setState(() {
        _amountController.text = maxAmount;
      });
    }
  }

  Future<void> _sendSuccessfulNotification(
    AccountBlockTemplate accountBlock,
  ) async {
    final String amount = accountBlock.amount.addDecimals(
      widget._token.decimals,
    );

    await sl.get<NotificationsBloc>().addNotification(
      WalletNotification(
        title: context.l10n.successfullyBurned(amount, widget._token.symbol),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: context.l10n.successfullyBurnedRequestedAmount(
          amount,
          accountBlock.hash,
          widget._token.symbol,
        ),
        type: NotificationType.burnToken,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
