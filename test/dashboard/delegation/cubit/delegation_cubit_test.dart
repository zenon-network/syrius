import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../../helpers/hydrated_bloc.dart';


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
    late DelegationStatsCubit delegationCubit;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    final DelegationInfo delegationInfo = DelegationInfo.fromJson(
      <String, dynamic>{'name': 'Test-Name', 'status': 1, 'weight': '1000'},
    );
    late NoDelegationStatsException delegationException;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      delegationException = NoDelegationStatsException();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillar);
      when(() => mockPillar.getDelegatedPillar(any()))
          .thenAnswer((_) async => delegationInfo);

      delegationCubit = DelegationStatsCubit(
        address: emptyAddress,
        zenon: mockZenon,
      );
    });

    test('initial status is correct', () {
      expect(delegationCubit.state.status, TimerStatus.initial);
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const DelegationStatsState initialState = DelegationStatsState();

        final Map<String, dynamic>? serialized = delegationCubit.toJson(
          initialState,
        );
        final DelegationStatsState? deserialized = delegationCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const DelegationStatsState loadingState = DelegationStatsState(
          status: TimerStatus.loading,
        );

        final Map<String, dynamic>? serialized = delegationCubit.toJson(
          loadingState,
        );
        final DelegationStatsState? deserialized = delegationCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final DelegationStatsState successState = DelegationStatsState(
          status: TimerStatus.success,
          data: delegationInfo,
        );

        final Map<String, dynamic>? serialized = delegationCubit.toJson(
          successState,
        );
        final DelegationStatsState? deserialized = delegationCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(successState));
      });

      test('can (de)serialize failure state', () {
        final DelegationStatsState failureState = DelegationStatsState(
          status: TimerStatus.failure,
          error: delegationException,
        );

        final Map<String, dynamic>? serialized = delegationCubit.toJson(
          failureState,
        );
        final DelegationStatsState? deserialized = delegationCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });


    group('fetchDataPeriodically', () {
      blocTest<DelegationStatsCubit, DelegationStatsState>(
        'calls getDelegatedPillar once',
        build: () => delegationCubit,
        act: (DelegationStatsCubit cubit) => cubit.fetchDataPeriodically(),
        verify: (_) {
          verify(
            () => mockZenon.embedded.pillar.getDelegatedPillar(
              emptyAddress,
            ),
          ).called(1);
        },
      );

      blocTest<DelegationStatsCubit, DelegationStatsState>(
        'emits [loading, failure] when getDelegatedPillar throws',
        setUp: () {
          when(
            () => mockPillar.getDelegatedPillar(
              any(),
            ),
          ).thenThrow(delegationException);
        },
        build: () => delegationCubit,
        act: (DelegationStatsCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <DelegationStatsState>[
          const DelegationStatsState(status: TimerStatus.loading),
          DelegationStatsState(
            status: TimerStatus.failure,
            error: delegationException,
          ),
        ],
      );

      blocTest<DelegationStatsCubit, DelegationStatsState>(
        'emits [loading, success] when getDelegatedPillar '
        'returns a DelegationInfo instance',
        build: () => delegationCubit,
        act: (DelegationStatsCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <dynamic>[
          const DelegationStatsState(status: TimerStatus.loading),
          DelegationStatsState(status: TimerStatus.success, data: delegationInfo),
        ],
      );
    });
  });
}
