// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillar extends Mock implements PillarApi {}

class MockDelegationInfo extends Mock implements DelegationInfo {}

class FakeAddress extends Fake implements Address {}


void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('DelegationCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late DelegationCubit delegationCubit;
    late DelegationInfo delegationInfo;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    late SyriusException delegationException;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      delegationInfo = DelegationInfo(
        name: 'testName',
        status: 1,
        weight: BigInt.from(1),
      );
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      delegationException = NoDelegationStatsException();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillar);
      when(() => mockPillar.getDelegatedPillar(any()))
          .thenAnswer((_) async => delegationInfo);

      delegationCubit = DelegationCubit(
        emptyAddress,
        mockZenon,
        DelegationState(),
      );
    });

    test('initial status is correct', () {
      expect(delegationCubit.state.status, TimerStatus.initial);
    });

    test('can be (de)serialized', () {
      final delegationState = DelegationState(status: TimerStatus.success, data: delegationInfo);
      final serialized = delegationCubit.toJson(delegationState);
      final deserialized = delegationCubit.fromJson(serialized!);
      expect(deserialized, delegationState);
    });

    group('fetchDataPeriodically', () {
      blocTest<DelegationCubit, TimerState>(
        'calls getDelegatedPillar once',
        build: () => delegationCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        verify: (_) {
          verify(() => mockPillar.getDelegatedPillar(
                emptyAddress,
              ),).called(1);
        },
      );

      blocTest<DelegationCubit, TimerState>(
        'emits [loading, failure] when getDelegatedPillar throws',
        setUp: () {
          when(
            () => mockPillar.getDelegatedPillar(
              any(),
            ),
          ).thenThrow(delegationException);
        },
        build: () => delegationCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => <DelegationState>[
          DelegationState(status: TimerStatus.loading),
          DelegationState(
            status: TimerStatus.failure,
            error: delegationException,
          ),
        ],
      );

      blocTest<DelegationCubit, TimerState>(
        'emits [loading, success] when getDelegatedPillar '
        'returns a DelegationInfo instance',
        build: () => delegationCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => <DelegationState>[
          DelegationState(status: TimerStatus.loading),
          DelegationState(
            status: TimerStatus.success,
            data: delegationInfo,
          ),
        ],
      );
    });
  });
}
