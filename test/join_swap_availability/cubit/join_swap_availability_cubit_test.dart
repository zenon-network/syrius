import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void main() {
  const int latestSafeJoinTimestamp = 100000;
  final HtlcInfo initialHtlc = HtlcInfo(
    id: Hash.digest(<int>[1, 2, 3]),
    timeLocked: htlcAddress,
    hashLocked: emptyAddress,
    tokenStandard: znnZts,
    amount: BigInt.one,
    expirationTime:
        latestSafeJoinTimestamp +
        kMinSafeTimeToFindPreimage.inSeconds +
        kCounterHtlcDuration.inSeconds,
    hashType: htlcHashTypeSha3,
    keyMaxSize: htlcPreimageMaxLength,
    hashLock: <int>[4, 5, 6],
  );
  late DateTime dateTime;

  setUp(() {
    dateTime = DateTime.fromMillisecondsSinceEpoch(
      latestSafeJoinTimestamp * Duration.millisecondsPerSecond,
      isUtc: true,
    );
  });

  test('initial state is available before the cutoff', () async {
    dateTime = dateTime.subtract(const Duration(seconds: 1));
    final JoinSwapAvailabilityCubit cubit = JoinSwapAvailabilityCubit(
      initialHtlc: initialHtlc,
      refreshInterval: const Duration(days: 1),
      dateTime: () => dateTime,
    );

    expect(
      cubit.state,
      const JoinSwapAvailable(minutesLeftToJoin: 1),
    );
    await cubit.close();
  });

  test('initial state is available exactly at the cutoff', () async {
    final JoinSwapAvailabilityCubit cubit = JoinSwapAvailabilityCubit(
      initialHtlc: initialHtlc,
      refreshInterval: const Duration(days: 1),
      dateTime: () => dateTime,
    );

    expect(
      cubit.state,
      const JoinSwapAvailable(minutesLeftToJoin: 0),
    );
    await cubit.close();
  });

  blocTest<JoinSwapAvailabilityCubit, JoinSwapAvailabilityState>(
    'emits unavailable after the cutoff',
    build: () => JoinSwapAvailabilityCubit(
      initialHtlc: initialHtlc,
      refreshInterval: const Duration(days: 1),
      dateTime: () => dateTime,
    ),
    act: (JoinSwapAvailabilityCubit cubit) {
      dateTime = dateTime.add(const Duration(seconds: 1));
      cubit.checkAvailability();
    },
    expect: () => <JoinSwapAvailabilityState>[
      const JoinSwapUnavailable(),
    ],
  );
}
