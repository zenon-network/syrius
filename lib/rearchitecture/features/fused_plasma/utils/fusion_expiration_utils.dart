import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Returns whether a Plasma fusion with [expirationHeight] is revocable at
/// [lastMomentumHeight] (strictly greater than [expirationHeight]).
bool isFusionRevocable({
  required int lastMomentumHeight,
  required int expirationHeight,
}) => lastMomentumHeight > expirationHeight;

/// Returns the remaining countdown duration in seconds until a Plasma fusion
/// with [expirationHeight] becomes revocable at [lastMomentumHeight].
///
/// Returns `0` once [isFusionRevocable] is `true`.
int computeFusionCountdownSeconds({
  required int lastMomentumHeight,
  required int expirationHeight,
}) {
  if (isFusionRevocable(
    lastMomentumHeight: lastMomentumHeight,
    expirationHeight: expirationHeight,
  )) {
    return 0;
  }
  final int remainingMomentums = expirationHeight - lastMomentumHeight;
  return kIntervalBetweenMomentums.inSeconds * remainingMomentums;
}
