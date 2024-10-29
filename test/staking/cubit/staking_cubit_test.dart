// ignore_for_file: prefer_const_constructors
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/rearchitecture.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockStake extends Mock implements StakeApi {}

class MockStakeList extends Mock implements StakeList {}

class FakeAddress extends Fake implements Address {}

class MockStakeEntry extends Fake implements StakeEntry {}


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
    late MockStakeList mockStakeList;
    late List<MockStakeEntry> mockStakeEntry;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockEmbedded = MockEmbedded();
      mockStake = MockStake();
      mockStakeEntry = [MockStakeEntry()];
      stakingCubit = StakingCubit(mockZenon, StakingState());
      mockStakeList = MockStakeList();
      stakingException = NoActiveStakingEntriesException();
      kSelectedAddress = 'z1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsggv2f';

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.stake).thenReturn(mockStake);
    });

    test('initial status is correct', () {
      final stakingCubit = StakingCubit(
        mockZenon,
        StakingState(),
      );
      expect(stakingCubit.state.status, TimerStatus.initial);
    });

    group('fetchDataPeriodically', () {
      blocTest<StakingCubit, StakingState>(
        'calls getEntriesByAddress() once',
        build: () => stakingCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        verify: (_) {
          verify(() => mockZenon.embedded.stake.getEntriesByAddress(
            emptyAddress,
          )).called(1);
        },
      );

      blocTest<StakingCubit, StakingState>(
        'emits [loading, failure] when getEntriesByAddress() throws',
        setUp: () {
          when(
                () => mockStake.getEntriesByAddress(any())
          ).thenThrow(stakingException);
        },
        build: () => stakingCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => <StakingState>[
          StakingState(status: TimerStatus.loading),
          StakingState(
            status: TimerStatus.failure,
            error: stakingException,
          ),
        ],
      );

      //TODO:TEST NOT WORKING; RETURN OBJECT NOT SERIALIZABLE.
      blocTest<StakingCubit, StakingState>(
          'emits [loading, success] when getAllActive() returns (sentinelInfoList)',
          setUp: () {
            when(
                    () => mockStakeList.list
            ).thenReturn(mockStakeEntry as List<StakeEntry>);
            when(
                  () => mockStake.getEntriesByAddress(any())
            ).thenAnswer((_) async => mockStakeList);
          },
          build: () => stakingCubit,
          act: (cubit) => cubit.fetchDataPeriodically(),
          expect: () => <StakingState>[
            StakingState(status: TimerStatus.loading),
            StakingState(status: TimerStatus.success,
            data: mockStakeList),
          ]
      );
    });
  });
}
