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

  group('PillarUncollectedRewardsCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late PillarUncollectedRewardsCubit pillarUncollectedRewardsCubit;
    late UncollectedReward uncollectedReward;
    late CubitFailureException exception;
    late Address testAddress;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockWsClient = MockWsClient();
      testAddress = FakeAddress();
      exception = CubitFailureException();

      final Map<String, dynamic> uncollectedRewardJson = <String, dynamic>{
        'address': emptyAddress.toString(),
        'znnAmount': '1',
        'qsrAmount': '1',
      };
      uncollectedReward = UncollectedReward.fromJson(uncollectedRewardJson);

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);

      pillarUncollectedRewardsCubit = PillarUncollectedRewardsCubit(
        zenon: mockZenon,
        address: testAddress,
        callUpdateStream: false,
      );
    });

    tearDown(() {
      pillarUncollectedRewardsCubit.close();
    });

    test('initial state is correct', () {
      expect(
        pillarUncollectedRewardsCubit.state.status,
        IndicatorStatus.initial,
      );
    });

    group('PillarUncollectedRewards toJson/fromJson', () {
      test('can (de)serialize initial state', () {
        const PillarUncollectedRewardsState initialState =
            PillarUncollectedRewardsState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final PillarUncollectedRewardsState deserialized =
            PillarUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const PillarUncollectedRewardsState loadingState =
            PillarUncollectedRewardsState(
          status: IndicatorStatus.loading,
        );

        final Map<String, dynamic> serialized = loadingState.toJson();
        final PillarUncollectedRewardsState deserialized =
            PillarUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final PillarUncollectedRewardsState successState =
            PillarUncollectedRewardsState(
          status: IndicatorStatus.success,
          data: uncollectedReward,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final PillarUncollectedRewardsState deserialized =
            PillarUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, isA<PillarUncollectedRewardsState>());
        expect(deserialized.status,
            equals(IndicatorStatus.success),);
        expect(deserialized.data, equals(uncollectedReward));
      });

      test('can (de)serialize failure state', () {
        final PillarUncollectedRewardsState failureState =
            PillarUncollectedRewardsState(
          status: IndicatorStatus.failure,
          error: exception,
        );
        final Map<String, dynamic> serialized = failureState.toJson();
        final PillarUncollectedRewardsState deserialized =
            PillarUncollectedRewardsState.fromJson(serialized);

        expect(deserialized, equals(failureState));
      });
    });

    group('updateStream', () {
      blocTest<PillarUncollectedRewardsCubit, PillarUncollectedRewardsState>(
        'emits [loading, success] when getData succeeds',
        setUp: () {
          when(() => mockPillarApi.getUncollectedReward(any()))
              .thenAnswer((_) async => uncollectedReward);
        },
        build: () => pillarUncollectedRewardsCubit,
        act: (PillarUncollectedRewardsCubit cubit) => cubit.updateStream(),
        expect: () => <PillarUncollectedRewardsState>[
          const PillarUncollectedRewardsState(
            status: IndicatorStatus.loading,
          ),
          PillarUncollectedRewardsState(
            status: IndicatorStatus.success,
            data: uncollectedReward,
          ),
        ],
      );

      blocTest<PillarUncollectedRewardsCubit, PillarUncollectedRewardsState>(
        'emits [loading, failure] when getData fails',
        setUp: () {
          when(() => mockPillarApi.getUncollectedReward(any()))
              .thenThrow(exception);
        },
        build: () => pillarUncollectedRewardsCubit,
        act: (PillarUncollectedRewardsCubit cubit) => cubit.updateStream(),
        expect: () => <PillarUncollectedRewardsState>[
          const PillarUncollectedRewardsState(
            status: IndicatorStatus.loading,
          ),
          PillarUncollectedRewardsState(
            status: IndicatorStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
