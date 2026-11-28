import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/utils/htlc_window_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Adds swap-specific formatting to [HtlcInfo].
extension HtlcInfoExtension on HtlcInfo {
  /// The hash lock encoded as a hexadecimal string.
  String get hashLockHex => FormatUtils.encodeHexString(hashLock);

  HtlcWindowDecision _windowDecisionAt(int unixTime) => evaluateHtlcJoinWindow(
    expirationTime: expirationTime,
    unixTime: unixTime,
    minRequiredSeconds:
        (kMinSafeTimeToFindPreimage + kCounterHtlcDuration).inSeconds,
  );

  /// Time remaining before this HTLC expires at [unixTime].
  Duration remainingDurationAt(int unixTime) =>
      Duration(seconds: _windowDecisionAt(unixTime).remainingSeconds);

  /// Time remaining before this HTLC can no longer be joined safely.
  Duration safeJoinWindowAt(int unixTime) =>
      Duration(seconds: _windowDecisionAt(unixTime).safeJoinSeconds);

  /// Whether this HTLC has enough time remaining to be joined safely.
  bool canBeSafelyJoinedAt(int unixTime) =>
      _windowDecisionAt(unixTime).canSafelyJoin;

  /// Whole or partial minutes remaining before this HTLC cannot be joined.
  int minutesLeftToJoinAt(int unixTime) =>
      _windowDecisionAt(unixTime).minutesLeftToJoin;
}
