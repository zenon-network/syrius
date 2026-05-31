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

  group('DelegationInfoCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late DelegationInfoCubit cubit;
    late DelegationInfo delegationInfo;
    late Address testAddress;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockWsClient = MockWsClient();
      testAddress = emptyAddress;
      exception = FailureException();

      delegationInfo =
          DelegationInfo(name: 'test', status: 1, weight: BigInt.from(1));

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);

      // Initialize the bloc without calling updateStream automatically
      cubit = DelegationInfoCubit(
        zenon: mockZenon,
        address: testAddress, // Prevent automatic data fetching
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is correct', () {
      expect(cubit.state.status, CubitWithRefreshOptionStatus.loading);
    });

    group('DelegationInfo toJson/fromJson', () {
      test('can (de)serialize initial state', () {
        const DelegationInfoState initialState = DelegationInfoState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final DelegationInfoState deserialized =
            DelegationInfoState.fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const DelegationInfoState loadingState = DelegationInfoState();

        final Map<String, dynamic> serialized = loadingState.toJson();
        final DelegationInfoState deserialized =
            DelegationInfoState.fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final DelegationInfoState successState = DelegationInfoState(
          status: CubitWithRefreshOptionStatus.success,
          data: delegationInfo,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final DelegationInfoState deserialized =
            DelegationInfoState.fromJson(serialized);

        expect(deserialized, equals(successState));
      });

      test('can (de)serialize failure state', () {
        final DelegationInfoState failureState = DelegationInfoState(
          status: CubitWithRefreshOptionStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> serialized = failureState.toJson();
        final DelegationInfoState deserialized =
            DelegationInfoState.fromJson(serialized);

        expect(deserialized.status, equals(CubitWithRefreshOptionStatus.failure));
      });
    });

    group('updateStream', () {
      blocTest<DelegationInfoCubit, DelegationInfoState>(
        'emits [loading, success] when getData succeeds',
        setUp: () {
          when(() => mockPillarApi.getDelegatedPillar(any()))
              .thenAnswer((_) async => delegationInfo);
        },
        build: () => cubit,
        act: (DelegationInfoCubit cubit) => cubit.updateStream(
          address: testAddress,
        ),
        expect: () => <DelegationInfoState>[
          const DelegationInfoState(),
          DelegationInfoState(
            status: CubitWithRefreshOptionStatus.success,
            data: delegationInfo,
          ),
        ],
        verify: (_) {
          verify(() => mockPillarApi.getDelegatedPillar(testAddress)).called(1);
        },
      );

      blocTest<DelegationInfoCubit, DelegationInfoState>(
        'emits [loading, failure] when getData fails',
        setUp: () {
          when(() => mockPillarApi.getDelegatedPillar(any()))
              .thenThrow(exception);
        },
        build: () => cubit,
        act: (DelegationInfoCubit cubit) => cubit.updateStream(
          address: testAddress,
        ),
        expect: () => <DelegationInfoState>[
          const DelegationInfoState(),
          DelegationInfoState(
            status: CubitWithRefreshOptionStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
