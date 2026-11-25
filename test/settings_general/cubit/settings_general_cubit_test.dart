import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_general/settings_general.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockLedgerApi extends Mock implements LedgerApi {}

class MockStatsApi extends Mock implements StatsApi {}

class MockWsClient extends Mock implements WsClient {}

class MockMomentum extends Mock implements Momentum {}

void main() {
  initHydratedStorage();

  group('SettingsGeneralCubit', () {
    late MockZenon mockZenon;
    late MockLedgerApi mockLedgerApi;
    late MockStatsApi mockStatsApi;
    late MockWsClient mockWsClient;
    late MockMomentum mockMomentum;
    late Hash momentumHash;
    late NetworkInfo networkInfo;

    setUp(() {
      mockZenon = MockZenon();
      mockLedgerApi = MockLedgerApi();
      mockStatsApi = MockStatsApi();
      mockWsClient = MockWsClient();
      mockMomentum = MockMomentum();
      momentumHash = Hash.digest(<int>[7, 8, 9]);
      networkInfo = NetworkInfo.fromJson(<String, dynamic>{
        'numPeers': 2,
        'self': <String, dynamic>{'ip': '127.0.0.1', 'publicKey': 'self'},
        'peers': <Map<String, dynamic>>[
          <String, dynamic>{'ip': '1.1.1.1', 'publicKey': 'pk1'},
          <String, dynamic>{'ip': '2.2.2.2', 'publicKey': 'pk2'},
        ],
      });

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockZenon.ledger).thenReturn(mockLedgerApi);
      when(() => mockZenon.stats).thenReturn(mockStatsApi);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockMomentum.height).thenReturn(12345);
      when(() => mockMomentum.timestamp).thenReturn(1700000000);
      when(() => mockMomentum.hash).thenReturn(momentumHash);
      when(
        () => mockLedgerApi.getFrontierMomentum(),
      ).thenAnswer((_) async => mockMomentum);
      when(
        () => mockStatsApi.networkInfo(),
      ).thenAnswer((_) async => networkInfo);
    });

    test('initial state has TimerStatus.initial', () {
      final SettingsGeneralCubit cubit = SettingsGeneralCubit(zenon: mockZenon);
      addTearDown(cubit.close);

      expect(cubit.state, const SettingsGeneralState());
    });

    blocTest<SettingsGeneralCubit, SettingsGeneralState>(
      'emits [loading, success] with momentum and peer data',
      build: () => SettingsGeneralCubit(zenon: mockZenon),
      act: (SettingsGeneralCubit cubit) => cubit.fetchDataPeriodically(),
      expect: () => <SettingsGeneralState>[
        const SettingsGeneralState(status: TimerStatus.loading),
        SettingsGeneralState(
          status: TimerStatus.success,
          data: SettingsGeneralData(
            momentumHeight: 12345,
            momentumTimestamp: 1700000000,
            momentumHash: momentumHash.toString(),
            peerCount: 2,
          ),
        ),
      ],
    );

    blocTest<SettingsGeneralCubit, SettingsGeneralState>(
      'emits failure when WebSocket client is closed',
      setUp: () {
        when(() => mockWsClient.isClosed()).thenReturn(true);
      },
      build: () => SettingsGeneralCubit(zenon: mockZenon),
      act: (SettingsGeneralCubit cubit) => cubit.fetchDataPeriodically(),
      expect: () => <Object>[
        const SettingsGeneralState(status: TimerStatus.loading),
        isA<SettingsGeneralState>()
            .having(
              (SettingsGeneralState s) => s.status,
              'status',
              TimerStatus.failure,
            )
            .having(
              (SettingsGeneralState s) => s.error,
              'error',
              isA<SyriusException>(),
            ),
      ],
    );

    test('SettingsGeneralState JSON serialization round-trips', () {
      final SettingsGeneralState state = SettingsGeneralState(
        status: TimerStatus.success,
        data: SettingsGeneralData(
          momentumHeight: 42,
          momentumTimestamp: 1700000042,
          momentumHash: momentumHash.toString(),
          peerCount: 3,
        ),
      );
      expect(SettingsGeneralState.fromJson(state.toJson()), state);
    });
  });
}
