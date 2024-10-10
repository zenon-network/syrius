// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}

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
    late DelegationCubit delegationCubit;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    late MockDelegationInfo delegationInfo;

    setUp(() async {
      mockZenon = MockZenon();
      delegationCubit = DelegationCubit(emptyAddress, mockZenon, DelegationState());
      delegationInfo = MockDelegationInfo();
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      when(
              () => mockZenon.embedded
      ).thenReturn(mockEmbedded);

      when(
          () => mockEmbedded.pillar
      ).thenReturn(mockPillar);
      when(
          () => mockPillar.getDelegatedPillar(any())
      ).thenAnswer((_) async => delegationInfo);


    });

    test('initial status is correct', () {
      final DelegationCubit delegationCubit = DelegationCubit(
        emptyAddress,
        mockZenon,
        DelegationState(),
      );
      expect(delegationCubit.state.status, CubitStatus.initial);
    });

    group('fetch', () {
      blocTest<DelegationCubit, DashboardState>(
        'calls getDelegatedPillar once',
        build: () => delegationCubit,
        act: (cubit) => cubit.fetch(),
        verify: (_) {
          verify(() => mockZenon.embedded.pillar.getDelegatedPillar(
                emptyAddress,
              )).called(1);
        },
      );

      blocTest<DelegationCubit, DashboardState>(
        'emits [loading, failure] when getDelegatedPillar throws',
        setUp: () {
          when(
                () => mockZenon.embedded.pillar.getDelegatedPillar(emptyAddress),
          ).thenThrow(Exception('No delegation stats available - test'));
        },
        build: () => delegationCubit,
        act: (cubit) => cubit.fetch(),
        expect: () => <DelegationState>[
          DelegationState(status: CubitStatus.loading),
          DelegationState(status: CubitStatus.failure),
        ],
      );

      blocTest<DelegationCubit, DashboardState>(
          'emits [loading, success] when getDelegatedPillar returns (delegationInfo)',
          setUp: () {
            when(
                  () => mockZenon.embedded.pillar.getDelegatedPillar(any()),
            ).thenReturn(delegationInfo as Future<DelegationInfo?>);
          },
          build: () => delegationCubit,
          act: (cubit) => cubit.fetch,
          expect: () => <DelegationState>[
          DelegationState(status: CubitStatus.loading),
          DelegationState(status: CubitStatus.success),
      ]
      );
    });
  });
}
