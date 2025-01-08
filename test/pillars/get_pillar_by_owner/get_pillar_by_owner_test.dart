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
  registerFallbackValue(FakeAddress());

  group('GetPillarByOwner', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late GetPillarByOwnerCubit cubit;
    late Address testAddress;
    late FailureException exception;
    late List<PillarInfo> pillarInfo;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockWsClient = MockWsClient();
      testAddress = emptyAddress;
      exception = FailureException();

      final Map<String, int> pillarEpochJson = <String, int>{
        'producedMomentums': 100,
        'expectedMomentums': 150,
      };

      final Map<String, dynamic> pillarInfoJson = <String, dynamic>{
        'name': 'PillarOne',
        'rank': 1,
        'type': 2,
        'ownerAddress': emptyAddress.toString(),
        'producerAddress': emptyAddress.toString(),
        'withdrawAddress': emptyAddress.toString(),
        'giveMomentumRewardPercentage': 1,
        'giveDelegateRewardPercentage': 2,
        'isRevocable': true,
        'revokeCooldown': 86400,
        'revokeTimestamp': 1650000000,
        'currentStats': pillarEpochJson,
        'weight': '500000000000000000000',
        'producedMomentums': 100,
        'expectedMomentums': 150,
      };

      pillarInfo = <PillarInfo>[
        PillarInfo.fromJson(pillarInfoJson),
      ];

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);

      // Initialize the cubit without calling updateStream automatically
      cubit = GetPillarByOwnerCubit(
        zenon: mockZenon,
        address: testAddress,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, CubitWithRefreshOptionStatus.loading);
    });

    group('GetPillarByOwn toJson/fromJson', () {
      test('can (de)serialize initial state', () {
        const GetPillarByOwnerState initialState = GetPillarByOwnerState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final GetPillarByOwnerState deserialized =
            GetPillarByOwnerState.fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const GetPillarByOwnerState loadingState = GetPillarByOwnerState();

        final Map<String, dynamic> serialized = loadingState.toJson();
        final GetPillarByOwnerState deserialized =
            GetPillarByOwnerState.fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final GetPillarByOwnerState successState = GetPillarByOwnerState(
          status: CubitWithRefreshOptionStatus.success,
          data: pillarInfo,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final GetPillarByOwnerState deserialized =
            GetPillarByOwnerState.fromJson(serialized);

        expect(deserialized, isA<GetPillarByOwnerState>());
        expect(
          deserialized.status,
          equals(CubitWithRefreshOptionStatus.success),
        );
        expect(deserialized.data, equals(pillarInfo));
      });

      test('can (de)serialize failure state', () {
        final GetPillarByOwnerState failureState = GetPillarByOwnerState(
          status: CubitWithRefreshOptionStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> serialized = failureState.toJson();
        final GetPillarByOwnerState deserialized =
            GetPillarByOwnerState.fromJson(serialized);

        expect(deserialized.status, equals(CubitWithRefreshOptionStatus.failure));
      });
    });

    group('updateStream', () {
      blocTest<GetPillarByOwnerCubit, GetPillarByOwnerState>(
        'emits [loading, success] when getData succeeds',
        setUp: () {
          when(() => mockPillarApi.getByOwner(any()))
              .thenAnswer((_) async => pillarInfo);
        },
        build: () => cubit,
        act: (GetPillarByOwnerCubit cubit) => cubit.updateStream(
          address: testAddress
        ),
        expect: () => <GetPillarByOwnerState>[
          const GetPillarByOwnerState(),
          GetPillarByOwnerState(
            status: CubitWithRefreshOptionStatus.success,
            data: pillarInfo,
          ),
        ],
        verify: (_) {
          verify(() => mockPillarApi.getByOwner(testAddress)).called(1);
        },
      );

      blocTest<GetPillarByOwnerCubit, GetPillarByOwnerState>(
        'emits [loading, failure] when getData fails',
        setUp: () {
          when(() => mockPillarApi.getByOwner(any())).thenThrow(exception);
        },
        build: () => cubit,
        act: (GetPillarByOwnerCubit cubit) => cubit.updateStream(
          address: testAddress,
        ),
        expect: () => <GetPillarByOwnerState>[
          const GetPillarByOwnerState(),
          GetPillarByOwnerState(
            status: CubitWithRefreshOptionStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
