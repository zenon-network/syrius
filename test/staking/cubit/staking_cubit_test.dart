// ignore_for_file: prefer_const_constructors
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/rearchitecture.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockStake extends Mock implements StakeApi {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('StakingCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late StakingCubit stakingCubit;
    late MockEmbedded mockEmbedded;
    late MockStake mockStake;
    late SyriusException stakingException;
    late StakeEntry stakeEntry;
    late StakeList testStakeList;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockEmbedded = MockEmbedded();
      mockStake = MockStake();
      stakingCubit = StakingCubit(
        address: emptyAddress,
        zenon: mockZenon,
      );
      stakeEntry = StakeEntry(
        amount: BigInt.from(1),
        weightedAmount: BigInt.from(1),
        startTimestamp: 123,
        expirationTimestamp: 321,
        address: emptyAddress,
        id: emptyHash,
      );
      testStakeList = StakeList(
        totalAmount: BigInt.from(1),
        totalWeightedAmount: BigInt.from(1),
        count: 1,
        list: <StakeEntry>[stakeEntry],
      );
      stakingException = NoActiveStakingEntriesException();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.stake).thenReturn(mockStake);
      when(
        () => mockStake.getEntriesByAddress(any()),
      ).thenAnswer((_) async => testStakeList);
    });

    test('initial status is correct', () {
      expect(stakingCubit.state.status, TimerStatus.initial);
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        final StakingState initialState = StakingState();

        final Map<String, dynamic>? serialized = stakingCubit.toJson(
          initialState,
        );
        final StakingState? deserialized = stakingCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        final StakingState loadingState = StakingState(
          status: TimerStatus.loading,
        );

        final Map<String, dynamic>? serialized = stakingCubit.toJson(
          loadingState,
        );
        final StakingState? deserialized = stakingCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final StakingState successState = StakingState(
          status: TimerStatus.success,
          data: testStakeList,
        );

        final Map<String, dynamic>? serialized = stakingCubit.toJson(
          successState,
        );
        final StakingState? deserialized = stakingCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(successState));
      });

      test('can (de)serialize failure state', () {
        final StakingState failureState = StakingState(
          status: TimerStatus.failure,
          error: stakingException,
        );

        final Map<String, dynamic>? serialized = stakingCubit.toJson(
          failureState,
        );
        final StakingState? deserialized = stakingCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    group('fetchDataPeriodically', () {
      blocTest<StakingCubit, StakingState>(
        'calls getEntriesByAddress() once',
        build: () => stakingCubit,
        act: (StakingCubit cubit) => cubit.fetchDataPeriodically(),
        verify: (_) {
          verify(
            () => mockZenon.embedded.stake.getEntriesByAddress(
              any(),
            ),
          ).called(1);
        },
      );

      blocTest<StakingCubit, StakingState>(
        'emits [loading, failure] when getEntriesByAddress() throws',
        setUp: () {
          when(
            () => mockStake.getEntriesByAddress(any()),
          ).thenThrow(stakingException);
        },
        build: () => stakingCubit,
        act: (StakingCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <StakingState>[
          StakingState(status: TimerStatus.loading),
          StakingState(
            status: TimerStatus.failure,
            error: stakingException,
          ),
        ],
      );

      blocTest<StakingCubit, StakingState>(
        'emits [loading, success] when getAllActive() returns successfully',
        build: () => stakingCubit,
        act: (StakingCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <StakingState>[
          StakingState(status: TimerStatus.loading),
          StakingState(
            status: TimerStatus.success,
            data: testStakeList,
          ),
        ],
      );
    });
  });
}
