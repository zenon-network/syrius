import 'package:equatable/equatable.dart';

/// Default minimum remaining duration in seconds required to safely join an
/// initial HTLC: `kMinSafeTimeToFindPreimage` (6h) + `kCounterHtlcDuration`
/// (1h) = 7 hours (25,200 seconds).
const int kDefaultMinSafeJoinSeconds = 7 * Duration.secondsPerHour;

/// Pure time-window evaluation for joining an initial HTLC.
class HtlcWindowDecision extends Equatable {
  /// Creates an [HtlcWindowDecision].
  const HtlcWindowDecision({
    required this.remainingSeconds,
    required this.safeJoinSeconds,
    required this.canSafelyJoin,
    required this.minutesLeftToJoin,
  });

  /// Seconds remaining until the HTLC expires (`expirationTime - unixTime`).
  final int remainingSeconds;

  /// Seconds remaining before the safe-join cutoff
  /// (`remainingSeconds - minRequiredSeconds`).
  final int safeJoinSeconds;

  /// Whether the HTLC can still be safely joined (`safeJoinSeconds >= 0`).
  final bool canSafelyJoin;

  /// Whole or partial minutes remaining until the safe-join cutoff.
  final int minutesLeftToJoin;

  @override
  List<Object> get props => <Object>[
    remainingSeconds,
    safeJoinSeconds,
    canSafelyJoin,
    minutesLeftToJoin,
  ];
}

/// Evaluates whether an initial HTLC expiring at [expirationTime] can be
/// safely joined at [unixTime] given [minRequiredSeconds] safety margin.
HtlcWindowDecision evaluateHtlcJoinWindow({
  required int expirationTime,
  required int unixTime,
  int minRequiredSeconds = kDefaultMinSafeJoinSeconds,
}) {
  final int remainingSeconds = expirationTime - unixTime;
  final int safeJoinSeconds = remainingSeconds - minRequiredSeconds;
  final bool canSafelyJoin = safeJoinSeconds >= 0;
  final int minutesLeftToJoin =
      (safeJoinSeconds / Duration.secondsPerMinute).ceil();

  return HtlcWindowDecision(
    remainingSeconds: remainingSeconds,
    safeJoinSeconds: safeJoinSeconds,
    canSafelyJoin: canSafelyJoin,
    minutesLeftToJoin: minutesLeftToJoin,
  );
}

/// Evaluates whether an HTLC expiring at [expirationTime] has expired at
/// [unixTime] (`unixTime >= expirationTime`).
bool evaluateHtlcExpiration({
  required int expirationTime,
  required int unixTime,
}) => unixTime >= expirationTime;
