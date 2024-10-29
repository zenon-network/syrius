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

class MockTokenApi extends Mock implements TokenApi {}

class MockToken extends Mock implements Token {}

class FakeTokenStandard extends Fake implements TokenStandard {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeTokenStandard());
  });

  group('DualCoinStatsCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockWsClient mockWsClient;
    late MockTokenApi mockTokenApi;
    late DualCoinStatsCubit dualCoinStatsCubit;
    late SyriusException exception;
    late MockToken mockTokenZnn;
    late MockToken mockTokenQsr;

    setUp(() async {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockTokenApi = MockTokenApi();
      mockWsClient = MockWsClient();
      exception = SyriusException('');
      mockTokenZnn = MockToken();
      mockTokenQsr = MockToken();
      dualCoinStatsCubit = DualCoinStatsCubit(mockZenon, DualCoinStatsState());

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.token).thenReturn(mockTokenApi);


      when(() => mockTokenApi.getByZts(znnZts)).thenAnswer((_) async => mockTokenZnn);
      when(() => mockTokenApi.getByZts(qsrZts)).thenAnswer((_) async => mockTokenQsr);
    });

    test('initial status is correct', () {
      final dualCoinStatsCubit = DualCoinStatsCubit(
        mockZenon,
        DualCoinStatsState(),
      );
      expect(dualCoinStatsCubit.state.status, TimerStatus.initial);
    });

      blocTest<DualCoinStatsCubit,TimerState>(
        'calls getByZts for each address in token once',
        build: () => dualCoinStatsCubit,
        setUp: () {

        },
        act: (cubit) => cubit.fetch(),
        verify: (_) {
          verify(() => mockTokenApi.getByZts(znnZts)).called(1);
          verify(() => mockTokenApi.getByZts(qsrZts)).called(1);
        },
      );

      //TODO: does not work
    blocTest<DualCoinStatsCubit, TimerState>(
      'emits [loading, failure] when getByZts throws',
      setUp: () {
        when(
                () => mockTokenApi.getByZts(any())
        ).thenThrow(exception);
      },
      build: () => dualCoinStatsCubit,
      act: (cubit) => cubit.fetchDataPeriodically(),
      expect: () => <DualCoinStatsState>[
        DualCoinStatsState(status: TimerStatus.loading),
        DualCoinStatsState(
          status: TimerStatus.failure,
          error: exception,
        ),
      ],
    );


    //TODO: does not work
    blocTest<DualCoinStatsCubit, TimerState>(
        'emits [loading, success] when getByZts returns',
        build: () => dualCoinStatsCubit,
        act: (cubit) => cubit.fetchDataPeriodically(),
        expect: () => <DualCoinStatsState>[
          DualCoinStatsState(status: TimerStatus.loading),
          DualCoinStatsState(
            status: TimerStatus.success,
            data: [mockTokenZnn, mockTokenQsr]
          ),
        ]
    );
  });
}