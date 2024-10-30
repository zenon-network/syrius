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

class MockSentinel extends Mock implements SentinelApi {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockSentinelInfoList extends Mock implements SentinelInfoList {}


void main() {
  initHydratedStorage();

  group('SentinelsCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late SentinelsCubit sentinelsCubit;
    late CubitFailureException exception;
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
      sentinelInfoList = SentinelInfoList(count: 1,
          list: <SentinelInfo>[sentinelInfo],
      );
      sentinelsCubit = SentinelsCubit(
          zenon: mockZenon,
      );
      exception = CubitFailureException();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(
              () => mockZenon.embedded,
      ).thenReturn(mockEmbedded);
      when(
              () => mockEmbedded.sentinel,
      ).thenReturn(mockSentinel);
    });

    test('initial status is correct', () {
      final SentinelsCubit sentinelsCubit = SentinelsCubit(
        zenon: mockZenon,
      );
      expect(sentinelsCubit.state.status, TimerStatus.initial);
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        final SentinelsState initialState = SentinelsState();

        final Map<String, dynamic>? serialized = sentinelsCubit.toJson(
          initialState,
        );
        final SentinelsState? deserialized = sentinelsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        final SentinelsState loadingState = SentinelsState(
          status: TimerStatus.loading,
        );

        final Map<String, dynamic>? serialized = sentinelsCubit.toJson(
          loadingState,
        );
        final SentinelsState? deserialized = sentinelsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      // TODO(mazznwell): to fix (equality between SentinelInfoList instances)
      test('can (de)serialize success state', () {
        final SentinelsState successState = SentinelsState(
          status: TimerStatus.success,
          data: sentinelInfoList,
        );

        final Map<String, dynamic>? serialized = sentinelsCubit.toJson(
          successState,
        );
        final SentinelsState? deserialized = sentinelsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(successState));
      });

      test('can (de)serialize failure state', () {
        final SentinelsState failureState = SentinelsState(
          status: TimerStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized = sentinelsCubit.toJson(
          failureState,
        );
        final SentinelsState? deserialized = sentinelsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    group('fetchDataPeriodically', () {
      blocTest<SentinelsCubit, SentinelsState>(
        'calls getAllActive() once',
        build: () => sentinelsCubit,
        act: (SentinelsCubit cubit) => cubit.fetchDataPeriodically(),
        verify: (_) {
          verify(() => mockZenon.embedded.sentinel.getAllActive()).called(1);
        },
      );

      blocTest<SentinelsCubit, SentinelsState>(
        'emits [loading, failure] when getAllActive() throws',
        setUp: () {
          when(
                () => mockSentinel.getAllActive(),
          ).thenThrow(exception);
        },
        build: () => sentinelsCubit,
        act: (SentinelsCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <SentinelsState>[
          SentinelsState(status: TimerStatus.loading),
          SentinelsState(
            status: TimerStatus.failure,
            error: exception,
          ),
        ],
      );

      blocTest<SentinelsCubit, SentinelsState>(
          'emits [loading, success] when getAllActive() returns successfully',
          setUp: () {
            when(
                  () => mockSentinel.getAllActive(),
            ).thenAnswer((_) async => sentinelInfoList);
          },
          build: () => sentinelsCubit,
          act: (SentinelsCubit cubit) => cubit.fetchDataPeriodically(),
          expect: () => <SentinelsState>[
            SentinelsState(status: TimerStatus.loading),
            SentinelsState(status: TimerStatus.success,
            data: sentinelInfoList,
            ),
          ],
      );
    });
  });
}
