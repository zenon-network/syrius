import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/functions/amount_max_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// An amount input with token-aware formatting and a maximum-balance action.
class AmountTextField extends StatelessWidget {
  /// Creates an amount input for the selected token and account.
  const AmountTextField({
    required this._accountInfo,
    required this._token,
    required this._controller,
    required this._errorText,
    required this._onSubmitted,
    this._enabled,
    this._focusNode,
    this._labelText,
    super.key,
  });

  final AccountInfo _accountInfo;
  final TextEditingController _controller;
  final String? _errorText;
  final FocusNode? _focusNode;
  final void Function(String) _onSubmitted;
  final Token _token;
  final String? _labelText;
  final bool? _enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: _enabled,
      key: const Key('send_amount_field'),
      controller: _controller,
      decoration: InputDecoration(
        errorText: _errorText,
        hintText: context.l10n.amount,
        labelText: _labelText,
        suffixIcon: TextButton(
          onPressed: _enabled == false
              ? null
              : () => _onMaxPressed(
                  accountInfo: _accountInfo,
                  selectedToken: _token,
                  controller: _controller,
                ),
          child: Text(context.l10n.max.toUpperCase()),
        ),
      ),
      focusNode: _focusNode,
      inputFormatters: FormatUtils.getAmountTextInputFormatters(
        _controller.text,
      ),
      onSubmitted: _onSubmitted,
    );
  }

  void _onMaxPressed({
    required AccountInfo accountInfo,
    required Token selectedToken,
    required TextEditingController controller,
  }) {
    final String amount = controller.text;

    final BigInt maxBalance = accountInfo.getBalance(
      selectedToken.tokenStandard,
    );

    BigInt? currentAmount;
    if (amount.isNotEmpty) {
      final List<String> parts = amount.split('.');
      final bool validFormat =
          parts.length <= 2 &&
          (parts.length == 1 || parts[1].length <= selectedToken.decimals);
      if (validFormat) {
        try {
          currentAmount = amount.extractDecimals(selectedToken.decimals);
        } on Object {
          currentAmount = null;
        }
      }
    }

    final String? nextText = resolveMaxAmountText(
      maxBalance: maxBalance,
      decimals: selectedToken.decimals,
      currentAmount: currentAmount,
    );
    if (nextText != null) {
      controller.text = nextText;
    }
  }
}
