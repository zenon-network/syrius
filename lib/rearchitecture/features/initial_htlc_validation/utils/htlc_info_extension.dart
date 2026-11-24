import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Adds swap-specific formatting to [HtlcInfo].
extension HtlcInfoExtension on HtlcInfo {
  /// The hash lock encoded as a hexadecimal string.
  String get hashLockHex => FormatUtils.encodeHexString(hashLock);

  /// Time remaining before this HTLC expires at [unixTime].
  Duration remainingDurationAt(int unixTime) =>
      Duration(seconds: expirationTime - unixTime);

  /// Time remaining before this HTLC can no longer be joined safely.
  Duration safeJoinWindowAt(int unixTime) =>
      remainingDurationAt(unixTime) -
      (kMinSafeTimeToFindPreimage + kCounterHtlcDuration);

  /// Whether this HTLC has enough time remaining to be joined safely.
  bool canBeSafelyJoinedAt(int unixTime) =>
      safeJoinWindowAt(unixTime) >= Duration.zero;

  /// Whole or partial minutes remaining before this HTLC cannot be joined.
  int minutesLeftToJoinAt(int unixTime) =>
      (safeJoinWindowAt(unixTime).inSeconds / Duration.secondsPerMinute).ceil();
}
