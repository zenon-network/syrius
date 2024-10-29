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
    late SyriusException sentinelsException;
    late SentinelInfoList mockSentinelInfoList;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      mockSentinelInfoList = MockSentinelInfoList();
      sentinelsCubit = SentinelsCubit(mockZenon, SentinelsState());
      sentinelsException = CubitFailureException();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(
              () => mockZenon.embedded
      ).thenReturn(mockEmbedded);
      when(
              () => mockEmbedded.sentinel
      ).thenReturn(mockSentinel);
    });

    test('initial status is correct', () {
      final sentinelsCubit = SentinelsCubit(
        mockZenon,
        SentinelsState(),
      );
      expect(sentinelsCubit.state.status, TimerStatus.initial);
    });

    group('fetchDataPeriodically', () {
      blocTest<SentinelsCubit, SentinelsState>(
        'calls getAllActive() once',
        build: () => sentinelsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        verify: (_) {
          verify(() => mockZenon.embedded.sentinel.getAllActive()
          ).called(1);
        },
      );

      blocTest<SentinelsCubit, SentinelsState>(
        'emits [loading, failure] when getAllActive() throws',
        setUp: () {
          when(
                () => mockSentinel.getAllActive(),
          ).thenThrow(sentinelsException);
        },
        build: () => sentinelsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => <SentinelsState>[
          SentinelsState(status: TimerStatus.loading),
          SentinelsState(
            status: TimerStatus.failure,
            error: sentinelsException,
          ),
        ],
      );

      blocTest<SentinelsCubit, SentinelsState>(
          'emits [loading, success] when getAllActive() returns successfully',
          setUp: () {
            when(
                  () => mockSentinel.getAllActive(),
            ).thenAnswer((_) async => mockSentinelInfoList);
          },
          build: () => sentinelsCubit,
          act: (cubit) => cubit.fetchDataPeriodically(),
          expect: () => <SentinelsState>[
            SentinelsState(status: TimerStatus.loading),
            SentinelsState(status: TimerStatus.success,
            data: mockSentinelInfoList),
          ]
      );
    });
  });
}
