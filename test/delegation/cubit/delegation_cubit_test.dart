// ignore_for_file: prefer_const_constructors

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillar extends Mock implements PillarApi {}

class MockDelegationInfo extends Mock implements DelegationInfo {}

class FakeAddress extends Fake implements Address {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('DelegationCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late DelegationCubit delegationCubit;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    late MockDelegationInfo delegationInfo;
    late Exception delegationException;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      delegationInfo = MockDelegationInfo();
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      delegationException = Exception('No delegation stats available - test');

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
      expect(delegationCubit.state.status, CubitStatus.initial);
    });

    group('fetchDataPeriodically', () {
      blocTest<DelegationCubit, DashboardState>(
        'calls getDelegatedPillar once',
        build: () => delegationCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        verify: (_) {
          verify(() => mockZenon.embedded.pillar.getDelegatedPillar(
                emptyAddress,
              ),).called(1);
        },
      );

      blocTest<DelegationCubit, DashboardState>(
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
          DelegationState(status: CubitStatus.loading),
          DelegationState(
            status: CubitStatus.failure,
            error: delegationException,
          ),
        ],
      );

      blocTest<DelegationCubit, DashboardState>(
        'emits [loading, success] when getDelegatedPillar '
        'returns a DelegationInfo instance',
        build: () => delegationCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => [
          DelegationState(status: CubitStatus.loading),
          isA<DelegationState>()
              .having((state) => state.status, 'status', CubitStatus.success),
        ],
      );
    });
  });
}
