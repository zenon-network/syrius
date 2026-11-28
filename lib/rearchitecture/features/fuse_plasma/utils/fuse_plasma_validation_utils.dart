import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

final RegExp _kIntegerQsrRegExp = RegExp(r'^[0-9]+$');

/// Returns whether [amountText] is a non-empty whole-number QSR string.
bool isIntegerQsrAmount(String amountText) =>
    _kIntegerQsrRegExp.hasMatch(amountText);

/// Returns whether a Plasma fusion request with [amountText], [maxQsrBalance],
/// and [beneficiaryAddress] satisfies protocol and UI validation rules.
bool canFusePlasma({
  required String amountText,
  required BigInt maxQsrBalance,
  required String beneficiaryAddress,
}) {
  if (!isIntegerQsrAmount(amountText)) {
    return false;
  }
  if (beneficiaryAddress.isEmpty || !Address.isValid(beneficiaryAddress)) {
    return false;
  }
  final BigInt amount = amountText.extractDecimals(coinDecimals);
  return amount >= fuseMinQsrAmount && amount <= maxQsrBalance;
}
