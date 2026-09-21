import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/mint_token/bloc/mint_token_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the form used to mint an amount of a ZTS token.
class MintTokenView extends StatelessWidget {
  /// Creates a [MintTokenView].
  const MintTokenView({
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
    return BlocProvider<MintTokenBloc>(
      create: (_) => MintTokenBloc(
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
  final TextEditingController _beneficiaryAddressController =
      TextEditingController();

  BigInt get _maxAmount => widget._token.maxSupply - widget._token.totalSupply;

  String get _amount => _amountController.text;

  String? get _amountError => InputValidators.correctValue(
    _amount,
    _maxAmount,
    widget._token.decimals,
    BigInt.zero,
  );

  String get _beneficiaryAddress => _beneficiaryAddressController.text;

  String? get _beneficiaryAddressError => InputValidators.checkAddress(
    _beneficiaryAddress,
  );

  @override
  void initState() {
    super.initState();
    _beneficiaryAddressController.text = kSelectedAddress!;
    _beneficiaryAddressController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MintTokenBloc, MintTokenState>(
      listener: _onMintTokenStateChanged,
      child: ListView(
        children: <Widget>[
          TextField(
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp('[0-9a-z]')),
            ],
            controller: _beneficiaryAddressController,
            decoration: InputDecoration(
              errorText: _beneficiaryAddress.isEmpty
                  ? null
                  : _beneficiaryAddressError,
              hintText: context.l10n.beneficiaryAddress,
              suffixIcon: FieldSuffixButtons(
                controller: _beneficiaryAddressController,
              ),
            ),
          ),
          StepperUtils.getBalanceWidget(widget._token, widget._accountInfo),
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
          kVerticalSpacing,
          Column(
            children: <Widget>[
              _buildMintButton(),
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

  Widget _buildMintButton() {
    final bool canMint =
        _beneficiaryAddress.isNotEmpty &&
        _beneficiaryAddressError == null &&
        _maxAmount > BigInt.zero &&
        _amount.isNotEmpty &&
        _amountError == null;

    return LoadingButton.stepper(
      text: context.l10n.mint,
      onPressed: canMint ? _mintToken : null,
      key: _buttonKey,
    );
  }

  void _mintToken() {
    context.read<MintTokenBloc>().add(
      MintTokenRequested(
        amount: _amount.extractDecimals(widget._token.decimals),
        beneficiaryAddress: Address.parse(_beneficiaryAddress),
        token: widget._token,
      ),
    );
  }

  void _onMaxPressed() {
    final String maxAmount = _maxAmount.addDecimals(widget._token.decimals);
    if (_amount != maxAmount) {
      setState(() {
        _amountController.text = maxAmount;
      });
    }
  }

  void _onMintTokenStateChanged(BuildContext context, MintTokenState state) {
    if (state is MintTokenLoading) {
      _buttonKey.currentState?.animateForward();
    } else if (state is MintTokenDone) {
      _amountController.clear();
      _buttonKey.currentState?.animateReverse();
      unawaited(_sendSuccessfulNotification(state.accountBlock));
    } else if (state is MintTokenFailure) {
      _buttonKey.currentState?.animateReverse();
      unawaited(
        NotificationUtils.sendNotificationError(
          state.exception,
          context.l10n.errorMintingToken(widget._token.symbol),
        ),
      );
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
        title: context.l10n.successfullyMinted(amount, widget._token.symbol),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: context.l10n.successfullyMintedRequestedAmount(
          amount,
          accountBlock.hash,
          widget._token.symbol,
        ),
        type: NotificationType.paymentSent,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _beneficiaryAddressController.dispose();
    super.dispose();
  }
}
