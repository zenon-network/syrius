import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void main() {
  const int latestSafeJoinTime = 100000;
  final Duration minimumRequiredDuration =
      kMinSafeTimeToFindPreimage + kCounterHtlcDuration;
  final HtlcInfo htlc = HtlcInfo(
    id: Hash.digest(<int>[1, 2, 3]),
    timeLocked: htlcAddress,
    hashLocked: emptyAddress,
    tokenStandard: znnZts,
    amount: BigInt.one,
    expirationTime: latestSafeJoinTime + minimumRequiredDuration.inSeconds,
    hashType: htlcHashTypeSha3,
    keyMaxSize: htlcPreimageMaxLength,
    hashLock: <int>[4, 5, 6],
  );

  test('is safe before the join cutoff', () {
    expect(htlc.canBeSafelyJoinedAt(latestSafeJoinTime - 1), isTrue);
    expect(htlc.minutesLeftToJoinAt(latestSafeJoinTime - 1), 1);
  });

  test('is safe exactly at the join cutoff', () {
    expect(htlc.canBeSafelyJoinedAt(latestSafeJoinTime), isTrue);
    expect(htlc.minutesLeftToJoinAt(latestSafeJoinTime), 0);
  });

  test('is unsafe after the join cutoff', () {
    expect(htlc.canBeSafelyJoinedAt(latestSafeJoinTime + 1), isFalse);
  });
}
