import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockTokenApi extends Mock implements TokenApi {}


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
    late CubitFailureException exception;

    setUp(() async {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockTokenApi = MockTokenApi();
      mockWsClient = MockWsClient();
      exception = CubitFailureException();
      dualCoinStatsCubit = DualCoinStatsCubit(
          zenon: mockZenon,
      );

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.token).thenReturn(mockTokenApi);


      when(() => mockTokenApi.getByZts(znnZts))
          .thenAnswer((_) async => kZnnCoin);
      when(() => mockTokenApi.getByZts(qsrZts))
          .thenAnswer((_) async => kQsrCoin);
    });

    test('initial status is correct', () {
      final DualCoinStatsCubit dualCoinStatsCubit = DualCoinStatsCubit(
        zenon: mockZenon,
      );
      expect(dualCoinStatsCubit.state.status, TimerStatus.initial);
    });
    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const DualCoinStatsState initialState = DualCoinStatsState();

        final Map<String, dynamic>? serialized = dualCoinStatsCubit.toJson(
          initialState,
        );
        final DualCoinStatsState? deserialized = dualCoinStatsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const DualCoinStatsState loadingState = DualCoinStatsState(
          status: TimerStatus.loading,
        );

        final Map<String, dynamic>? serialized = dualCoinStatsCubit.toJson(
          loadingState,
        );
        final DualCoinStatsState? deserialized = dualCoinStatsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final DualCoinStatsState dualCoinStatsState = DualCoinStatsState(
          data: <Token>[kZnnCoin, kQsrCoin],
          status: TimerStatus.success,
        );

        final Map<String, dynamic>? serialized =dualCoinStatsCubit.toJson(
          dualCoinStatsState,
        );
        final DualCoinStatsState? deserialized = dualCoinStatsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, dualCoinStatsState);
      });

      test('can (de)serialize failure state', () {
        final DualCoinStatsState failureState = DualCoinStatsState(
          status: TimerStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized = dualCoinStatsCubit.toJson(
          failureState,
        );
        final DualCoinStatsState? deserialized = dualCoinStatsCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });


      blocTest<DualCoinStatsCubit, DualCoinStatsState>(
        'calls getByZts for each address in token once',
        build: () => dualCoinStatsCubit,
        setUp: () {

        },
        act: (DualCoinStatsCubit cubit) => cubit.fetch(),
        verify: (_) {
          verify(() => mockTokenApi.getByZts(znnZts)).called(1);
          verify(() => mockTokenApi.getByZts(qsrZts)).called(1);
        },
      );

    blocTest<DualCoinStatsCubit, DualCoinStatsState>(
      'emits [loading, failure] when getByZts throws',
      setUp: () {
        when(
                () => mockTokenApi.getByZts(any()),
        ).thenThrow(exception);
      },
      build: () => dualCoinStatsCubit,
      act: (DualCoinStatsCubit cubit) => cubit.fetchDataPeriodically(),
      expect: () => <DualCoinStatsState>[
        const DualCoinStatsState(status: TimerStatus.loading),
        DualCoinStatsState(
          status: TimerStatus.failure,
          error: exception,
        ),
      ],
    );

    blocTest<DualCoinStatsCubit, DualCoinStatsState>(
        'emits [loading, success] when getByZts returns',
        build: () => dualCoinStatsCubit,
        act: (DualCoinStatsCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <DualCoinStatsState>[
          const DualCoinStatsState(status: TimerStatus.loading),
          DualCoinStatsState(
            status: TimerStatus.success,
            data: <Token>[kZnnCoin, kQsrCoin],
          ),
        ],
    );
  });
}
