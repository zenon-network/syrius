import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';

/// Computes the formatted text to write into an amount input when MAX is
/// pressed, or `null` when [currentAmount] already matches the effective
/// maximum.
///
/// Negative [maxBalance] values are clamped to zero. When [currentAmount] is
/// `null` (empty or unparseable) or differs from the effective maximum (either
/// below or above it), the formatted effective maximum is returned.
String? resolveMaxAmountText({
  required BigInt maxBalance,
  required int decimals,
  required BigInt? currentAmount,
}) {
  final BigInt effectiveMax = maxBalance < BigInt.zero
      ? BigInt.zero
      : maxBalance;
  if (currentAmount == effectiveMax) {
    return null;
  }
  return effectiveMax.addDecimals(decimals);
}
