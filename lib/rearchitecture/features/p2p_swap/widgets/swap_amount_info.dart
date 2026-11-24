import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays a token amount, or a placeholder when amount data is incomplete.
class SwapAmountInfo extends StatelessWidget {
  /// Creates a [SwapAmountInfo].
  const SwapAmountInfo({
    required this._amount,
    required this._token,
    super.key,
  });

  final BigInt? _amount;
  final Token? _token;

  @override
  Widget build(BuildContext context) {
    final BigInt? amount = _amount;
    final Token? token = _token;
    if (amount == null || token == null) {
      return const Text('-');
    }

    return Text('${amount.addDecimals(token.decimals)} ${token.symbol}');
  }
}
