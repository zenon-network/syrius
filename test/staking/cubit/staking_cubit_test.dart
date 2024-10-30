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

class FakeAddress extends Fake implements Address {}

class FakeStakeEntry extends Fake implements StakeEntry {}


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
    late CubitException stakingException;
    late StakeList testStakeList;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockEmbedded = MockEmbedded();
      mockStake = MockStake();
      stakingCubit = StakingCubit(
          zenon: mockZenon,
      );
      testStakeList = StakeList(
        totalAmount: BigInt.from(1),
        totalWeightedAmount: BigInt.from(1),
        count: 1,
        list: <StakeEntry>[FakeStakeEntry()],
      );
      stakingException = NoActiveStakingEntriesException();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.stake).thenReturn(mockStake);
    });

    test('initial status is correct', () {
      final StakingCubit stakingCubit = StakingCubit(
        zenon:  mockZenon,
      );
      expect(stakingCubit.state.status, TimerStatus.initial);
    });

    group('fetchDataPeriodically', () {
      blocTest<StakingCubit, StakingState>(
        'calls getEntriesByAddress() once',
        build: () => stakingCubit,
        act: (StakingCubit cubit) => cubit.fetchDataPeriodically(),
        verify: (_) {
          verify(() => mockZenon.embedded.stake.getEntriesByAddress(
            any(),
          )
            ,)
              .called(1);
        },
      );

      blocTest<StakingCubit, StakingState>(
        'emits [loading, failure] when getEntriesByAddress() throws',
        setUp: () {
          when(
                () => mockStake.getEntriesByAddress(Address.parse(kSelectedAddress!)),
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

      //TODO:TEST NOT DONE
      blocTest<StakingCubit, StakingState>(
          'emits [loading, success] when getAllActive() returns successfully',
          setUp: () {
            when(
                  () => mockStake.getEntriesByAddress(any())
            ).thenAnswer((_) async => testStakeList);
          },
          build: () => stakingCubit,
          act: (StakingCubit cubit) => cubit.fetchDataPeriodically(),
          expect: () => <StakingState>[
            StakingState(status: TimerStatus.loading),
            StakingState(status: TimerStatus.success,
            data: testStakeList),
          ]
      );
    });
  });
}
