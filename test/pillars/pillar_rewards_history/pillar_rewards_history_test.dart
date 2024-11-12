import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('PillarRewardsHistoryCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late PillarRewardsHistoryCubit pillarRewardsHistoryCubit;
    late RewardHistoryList rewardHistoryList;
    late NoRewardsLastWeekException exception;
    late Address testAddress;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockWsClient = MockWsClient();
      testAddress = emptyAddress;
      exception = NoRewardsLastWeekException();

      final Map<String, dynamic> rewardHistoryListJson = <String, dynamic>{
        'count' : 2,
        'list': <Map<String, dynamic>>[
          <String, dynamic>{
            'epoch': 1,
            'znnAmount': '100',
            'qsrAmount': '50',
          },
          <String, dynamic>{
            'epoch': 1,
            'znnAmount': '0',
            'qsrAmount': '0',
          },
        ],
      };
      rewardHistoryList = RewardHistoryList.fromJson(rewardHistoryListJson);

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);

      pillarRewardsHistoryCubit = PillarRewardsHistoryCubit(
        zenon: mockZenon,
        address: testAddress,
        callUpdateStream: false,
      );
    });

    tearDown(() {
      pillarRewardsHistoryCubit.close();
    });

    test('initial state is correct', () {
      expect(
        pillarRewardsHistoryCubit.state.status,
        IndicatorStatus.initial,
      );
    });

    group('PillarRewardsHistory toJson/fromJson', () {
      test('can (de)serialize initial state', () {
        const PillarRewardsHistoryState initialState =
            PillarRewardsHistoryState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final PillarRewardsHistoryState deserialized =
            PillarRewardsHistoryState.fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const PillarRewardsHistoryState loadingState =
            PillarRewardsHistoryState(
          status: IndicatorStatus.loading,
        );

        final Map<String, dynamic> serialized = loadingState.toJson();
        final PillarRewardsHistoryState deserialized =
            PillarRewardsHistoryState.fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final PillarRewardsHistoryState successState =
            PillarRewardsHistoryState(
          status: IndicatorStatus.success,
          data: rewardHistoryList,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final PillarRewardsHistoryState deserialized =
            PillarRewardsHistoryState.fromJson(serialized);

        expect(deserialized, isA<PillarRewardsHistoryState>());
        expect(
          deserialized.status,
          equals(IndicatorStatus.success),
        );
        expect(deserialized.data, equals(rewardHistoryList));
      });

      test('can (de)serialize failure state', () {
        final PillarRewardsHistoryState failureState =
            PillarRewardsHistoryState(
          status: IndicatorStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> serialized = failureState.toJson();
        final PillarRewardsHistoryState deserialized =
            PillarRewardsHistoryState.fromJson(serialized);

        expect(deserialized, isA<PillarRewardsHistoryState>());
        expect(
          deserialized.status,
          equals(IndicatorStatus.failure),
        );
      });
    });

    group('updateStream', () {
      blocTest<PillarRewardsHistoryCubit, PillarRewardsHistoryState>(
        'emits [loading, success] when getData succeeds',
        setUp: () {
          when(
            () => mockPillarApi.getFrontierRewardByPage(
              any(),
              pageSize: any(named: 'pageSize'),
            ),
          ).thenAnswer((_) async => rewardHistoryList);
        },
        build: () => pillarRewardsHistoryCubit,
        act: (PillarRewardsHistoryCubit cubit) => cubit.updateStream(),
        expect: () => <PillarRewardsHistoryState>[
          const PillarRewardsHistoryState(
            status: IndicatorStatus.loading,
          ),
          PillarRewardsHistoryState(
            status: IndicatorStatus.success,
            data: rewardHistoryList,
          ),
        ],
      );

      blocTest<PillarRewardsHistoryCubit, PillarRewardsHistoryState>(
        'emits [loading, failure] when getData throws exception',
        setUp: () {
          when(
            () => mockPillarApi.getFrontierRewardByPage(
              any(),
              pageSize: any(named: 'pageSize'),
            ),
          ).thenThrow(exception);
        },
        build: () => pillarRewardsHistoryCubit,
        act: (PillarRewardsHistoryCubit cubit) => cubit.updateStream(),
        expect: () => <PillarRewardsHistoryState>[
          const PillarRewardsHistoryState(
            status: IndicatorStatus.loading,
          ),
          PillarRewardsHistoryState(
            status: IndicatorStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
