import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dropdown/coin_dropdown.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/amount_suffix_widgets.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/input_field.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AmountInputField extends StatefulWidget {
  final TextEditingController controller;
  final AccountInfo accountInfo;
  final void Function(Token, bool)? onChanged;
  final double? valuePadding;
  final Color? textColor;
  final Token? initialToken;
  final String hintText;
  final bool enabled;

  const AmountInputField({
    required this.controller,
    required this.accountInfo,
    this.onChanged,
    this.valuePadding,
    this.textColor,
    this.initialToken,
    this.hintText = 'Amount',
    this.enabled = true,
    Key? key,
  }) : super(key: key);

  @override
  State createState() {
    return _AmountInputFieldState();
  }
}

class _AmountInputFieldState extends State<AmountInputField> {
  final List<Token?> _tokensWithBalance = [];
  Token? _selectedToken;

  @override
  void initState() {
    super.initState();
    _tokensWithBalance.addAll(kDualCoin);
    _addTokensWithBalance();
    _selectedToken = widget.initialToken ?? kDualCoin.first;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.key,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: InputField(
        onChanged: (value) {
          setState(() {});
        },
        inputFormatters: FormatUtils.getAmountTextInputFormatters(
          widget.controller.text,
        ),
        validator: (value) => InputValidators.correctValue(
          value,
          widget.accountInfo.getBalance(
            _selectedToken!.tokenStandard,
          ),
          _selectedToken!.decimals,
          BigInt.zero,
        ),
        controller: widget.controller,
        suffixIcon: _getAmountSuffix(),
        hintText: widget.hintText,
        contentLeftPadding: widget.valuePadding ?? kContentPadding,
        enabled: widget.enabled,
      ),
      onChanged: () => (widget.onChanged != null)
          ? widget.onChanged!(_selectedToken!, (_isInputValid()) ? true : false)
          : null,
    );
  }

  Widget _getAmountSuffix() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _getCoinDropdown(),
        const SizedBox(
          width: 5.0,
        ),
        AmountSuffixMaxWidget(
          onPressed: () => _onMaxPressed(),
          context: context,
        ),
        const SizedBox(
          width: 5.0,
        ),
      ],
    );
  }

  void _onMaxPressed() => setState(() {
        final maxBalance = widget.accountInfo.getBalance(
          _selectedToken!.tokenStandard,
        );
        widget.controller.text =
            maxBalance.addDecimals(_selectedToken!.decimals).toString();
      });

  Widget _getCoinDropdown() => CoinDropdown(
        _tokensWithBalance,
        _selectedToken!,
        (value) {
          if (_selectedToken != value) {
            setState(
              () {
                _selectedToken = value!;
                _isInputValid();
                widget.onChanged!(_selectedToken!, _isInputValid());
              },
            );
          }
        },
      );

  void _addTokensWithBalance() {
    for (var balanceInfo in widget.accountInfo.balanceInfoList!) {
      if (balanceInfo.balance! > BigInt.zero &&
          !_tokensWithBalance.contains(balanceInfo.token)) {
        _tokensWithBalance.add(balanceInfo.token);
      }
    }
  }

  bool _isInputValid() =>
      InputValidators.correctValue(
        widget.controller.text,
        widget.accountInfo.getBalance(
          _selectedToken!.tokenStandard,
        ),
        _selectedToken!.decimals,
        BigInt.zero,
      ) ==
      null;

  @override
  void dispose() {
    super.dispose();
  }
}
