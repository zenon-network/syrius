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

class MockSentinel extends Mock implements SentinelApi {}

class MockEmbedded extends Mock implements EmbeddedApi {}

void main() {
  initHydratedStorage();

  group('ActiveSentinelsCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late ActiveSentinelsCubit activeSentinelsCubit;
    late FailureException exception;
    late SentinelInfo sentinelInfo;
    late SentinelInfoList sentinelInfoList;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      sentinelInfo = SentinelInfo.fromJson(
        <String, dynamic>{
          'owner': emptyAddress.toString(),
          'registrationTimestamp': 1625132800,
          'isRevocable': true,
          'revokeCooldown': 1000,
          'active': true,
        },
      );
      sentinelInfoList = SentinelInfoList(
        count: 1,
        list: <SentinelInfo>[sentinelInfo],
      );
      activeSentinelsCubit = ActiveSentinelsCubit(
        zenon: mockZenon,
      );
      exception = FailureException();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(
        () => mockZenon.embedded,
      ).thenReturn(mockEmbedded);
      when(
        () => mockEmbedded.sentinel,
      ).thenReturn(mockSentinel);
      when(
        () => mockSentinel.getAllActive(),
      ).thenAnswer((_) async => sentinelInfoList);
    });

    test('initial status is correct', () {
      final ActiveSentinelsCubit activeSentinelsCubit = ActiveSentinelsCubit(
        zenon: mockZenon,
      );
      expect(activeSentinelsCubit.state.status, TimerStatus.initial);
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const ActiveSentinelsState initialState = ActiveSentinelsState();

        final Map<String, dynamic>? serialized = activeSentinelsCubit.toJson(
          initialState,
        );
        final ActiveSentinelsState? deserialized = activeSentinelsCubit
            .fromJson(
              serialized!,
            );
        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const ActiveSentinelsState loadingState = ActiveSentinelsState(
          status: TimerStatus.loading,
        );

        final Map<String, dynamic>? serialized = activeSentinelsCubit.toJson(
          loadingState,
        );
        final ActiveSentinelsState? deserialized = activeSentinelsCubit
            .fromJson(
              serialized!,
            );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final ActiveSentinelsState successState = ActiveSentinelsState(
          status: TimerStatus.success,
          data: sentinelInfoList,
        );

        final Map<String, dynamic>? serialized = activeSentinelsCubit.toJson(
          successState,
        );
        final ActiveSentinelsState? deserialized = activeSentinelsCubit
            .fromJson(
              serialized!,
            );
        expect(deserialized, equals(successState));
      });

      test('can (de)serialize failure state', () {
        final ActiveSentinelsState failureState = ActiveSentinelsState(
          status: TimerStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized = activeSentinelsCubit.toJson(
          failureState,
        );
        final ActiveSentinelsState? deserialized = activeSentinelsCubit
            .fromJson(
              serialized!,
            );
        expect(deserialized, equals(failureState));
      });
    });

    group('fetchDataPeriodically', () {
      blocTest<ActiveSentinelsCubit, ActiveSentinelsState>(
        'calls getAllActive() once',
        build: () => activeSentinelsCubit,
        act: (ActiveSentinelsCubit cubit) => cubit.fetchDataPeriodically(),
        verify: (_) {
          verify(() => mockZenon.embedded.sentinel.getAllActive()).called(1);
        },
      );

      blocTest<ActiveSentinelsCubit, ActiveSentinelsState>(
        'emits [loading, failure] when getAllActive() throws',
        setUp: () {
          when(
            () => mockSentinel.getAllActive(),
          ).thenThrow(exception);
        },
        build: () => activeSentinelsCubit,
        act: (ActiveSentinelsCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <ActiveSentinelsState>[
          const ActiveSentinelsState(status: TimerStatus.loading),
          ActiveSentinelsState(
            status: TimerStatus.failure,
            error: exception,
          ),
        ],
      );

      blocTest<ActiveSentinelsCubit, ActiveSentinelsState>(
        'emits [loading, success] when getAllActive() returns successfully',
        build: () => activeSentinelsCubit,
        act: (ActiveSentinelsCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <ActiveSentinelsState>[
          const ActiveSentinelsState(status: TimerStatus.loading),
          ActiveSentinelsState(
            status: TimerStatus.success,
            data: sentinelInfoList,
          ),
        ],
      );
    });
  });
}
