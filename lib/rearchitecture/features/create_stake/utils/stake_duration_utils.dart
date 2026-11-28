import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Converts a staking period in [months] into seconds using [stakeTimeUnitSec].
int stakeDurationForMonths(int months) => months * stakeTimeUnitSec;

/// Returns whether [months] corresponds to a protocol-valid staking duration
/// within `[stakeTimeMinSec, stakeTimeMaxSec]`.
bool isValidStakeMonths(int months) {
  final int durationSec = stakeDurationForMonths(months);
  return durationSec >= stakeTimeMinSec && durationSec <= stakeTimeMaxSec;
}

/// Builds the ordered list of protocol-valid staking [Duration] options
/// (`1` month through `stakeTimeMaxSec ~/ stakeTimeUnitSec` months).
List<Duration> buildValidStakeDurations() => List<Duration>.generate(
  stakeTimeMaxSec ~/ stakeTimeUnitSec,
  (int index) => Duration(seconds: stakeDurationForMonths(index + 1)),
);

/// Returns whether a staking request with [amountText], [maxZnnBalance], and
/// [months] satisfies protocol and UI validation rules.
bool canCreateStake({
  required String amountText,
  required BigInt maxZnnBalance,
  required int months,
}) {
  if (!isValidStakeMonths(months) || amountText.isEmpty) {
    return false;
  }
  final List<String> parts = amountText.split('.');
  if (parts.length > 2 ||
      (parts.length == 2 && parts[1].length > coinDecimals)) {
    return false;
  }
  final BigInt amount;
  try {
    amount = amountText.extractDecimals(coinDecimals);
  } on Object {
    return false;
  }
  return amount >= stakeMinZnnAmount && amount <= maxZnnBalance;
}
