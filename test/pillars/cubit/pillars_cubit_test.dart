// ignore_for_file: prefer_const_constructors
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/rearchitecture.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/cubit_exception.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/cubit_failure_exception.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillar extends Mock implements PillarApi {}

class MockPillarInfoList extends Mock implements PillarInfoList {}

class MockPillarInfo extends Mock implements PillarInfo {}

void main() {
  initHydratedStorage();

  group('PillarsCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    late PillarsCubit pillarsCubit;
    late CubitException exception;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      pillarsCubit = PillarsCubit(
        zenon: mockZenon,
      );
      exception = CubitFailureException();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillar);
    });

    test('initial status is correct', () {
      final PillarsCubit pillarsCubit = PillarsCubit(
        zenon: mockZenon,
      );
      expect(pillarsCubit.state.status, TimerStatus.initial);
    });

    //TODO: ADD SERIALIZATION TESTS
    group('fetch', () {
      blocTest<PillarsCubit, TimerState<int>>(
        'emits [loading, success] when fetch is successful',
        build: () => pillarsCubit,
        setUp: () {
          final mockPillarInfoList = MockPillarInfoList();
          final mockPillarInfo = MockPillarInfo();
          when(() => mockPillar.getAll())
              .thenAnswer((_) async => mockPillarInfoList);
          when(() => mockPillarInfoList.list)
              .thenReturn(List.filled(100, mockPillarInfo));
        },
        act: (PillarsCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <PillarsState>[
          PillarsState(status: TimerStatus.loading),
          PillarsState(status: TimerStatus.success, data: 100),
        ],
        verify: (_) {
          verify(() => mockPillar.getAll()).called(1);
        },
      );

      blocTest<PillarsCubit, TimerState>(
        'emits [loading, failure] when getAll() throws',
        setUp: () {
          when(() => mockPillar.getAll()).thenThrow(exception);
        },
        build: () => pillarsCubit,
        act: (PillarsCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <PillarsState>[
          PillarsState(status: TimerStatus.loading),
          PillarsState(status: TimerStatus.failure, error: exception),
        ],
      );
    });
  });
}
