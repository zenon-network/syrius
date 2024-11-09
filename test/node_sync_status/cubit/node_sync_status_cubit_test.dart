import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_receive_tx_worker.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/rearchitecture.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/cubit_failure_exception.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockStatsApi extends Mock implements StatsApi {}

class MockAutoReceiveTxWorker extends Mock implements AutoReceiveTxWorker {}

void main() {
  initHydratedStorage();

  group('NodeSyncStatusCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockStatsApi mockStatsApi;
    late NodeSyncStatusCubit nodeSyncStatusCubit;
    late CubitFailureException exception;
    late SyncInfo syncInfo;
    late Pair<SyncState, SyncInfo> syncPair;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockStatsApi = MockStatsApi();
      exception = CubitFailureException();
      nodeSyncStatusCubit = NodeSyncStatusCubit(
        zenon: mockZenon,
      );

      syncInfo = SyncInfo.fromJson(<String, dynamic>{
        'state': 2,
        'currentHeight': 100,
        'targetHeight': 120,
      });

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockWsClient.status()).thenReturn(WebsocketStatus.running);


      when(() => mockZenon.stats).thenReturn(mockStatsApi);
      when(() => mockStatsApi.syncInfo()).thenAnswer((_) async => syncInfo);

      syncPair = Pair<SyncState, SyncInfo>(SyncState.syncDone, syncInfo);
    });

    test('initial status is correct', () {
      expect(nodeSyncStatusCubit.state.status, TimerStatus.initial);
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const NodeSyncStatusState initialState = NodeSyncStatusState();

        final Map<String, dynamic>? serialized = nodeSyncStatusCubit.toJson(
          initialState,
        );
        final NodeSyncStatusState? deserialized = nodeSyncStatusCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const NodeSyncStatusState loadingState = NodeSyncStatusState(
          status: TimerStatus.loading,
        );

        final Map<String, dynamic>? serialized = nodeSyncStatusCubit.toJson(
          loadingState,
        );
        final NodeSyncStatusState? deserialized = nodeSyncStatusCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final NodeSyncStatusState successState = NodeSyncStatusState(
          status: TimerStatus.success,
          data: syncPair,
        );

        final Map<String, dynamic>? serialized = nodeSyncStatusCubit.toJson(
          successState,
        );
        final NodeSyncStatusState? deserialized = nodeSyncStatusCubit.fromJson(
          serialized!,
        );

        expect(deserialized, isA<NodeSyncStatusState>());
        expect(deserialized!.status, equals(TimerStatus.success));
        expect(deserialized.data, isA<Pair<SyncState, SyncInfo>>());
        expect(deserialized.data!.first, equals(SyncState.syncDone));
        expect(deserialized.data!.second, isA<SyncInfo>());
      });

      test('can (de)serialize failure state', () {
        final NodeSyncStatusState failureState = NodeSyncStatusState(
          status: TimerStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized = nodeSyncStatusCubit.toJson(
          failureState,
        );
        final NodeSyncStatusState? deserialized = nodeSyncStatusCubit.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    group('fetch', () {
      blocTest<NodeSyncStatusCubit, NodeSyncStatusState>(
        'emits [loading, success] when websocket is running and '
          'fetch returns syncInfo',
        build: () => nodeSyncStatusCubit,
        act: (NodeSyncStatusCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <NodeSyncStatusState>[ // Expected state changes
          const NodeSyncStatusState(status: TimerStatus.loading),
          NodeSyncStatusState(
            status: TimerStatus.success,
            data: syncPair,
          ),
        ],
      );


      blocTest<NodeSyncStatusCubit, NodeSyncStatusState>(
        'emits [loading, failure] when fetch throws an error',
        setUp: () {
          when(() => mockStatsApi.syncInfo()).thenThrow(exception);
        },
        build: () => nodeSyncStatusCubit,
        act: (NodeSyncStatusCubit cubit) => cubit.fetchDataPeriodically(),
        expect: () => <NodeSyncStatusState>[
          const NodeSyncStatusState(status: TimerStatus.loading),
          NodeSyncStatusState(
            status: TimerStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
