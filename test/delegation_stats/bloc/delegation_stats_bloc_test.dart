import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillar extends Mock implements PillarApi {}

class MockDelegationInfo extends Mock implements DelegationInfo {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('DelegationCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;
    late DelegationStatsBloc delegationStatsBloc;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    final DelegationInfo delegationInfo = DelegationInfo.fromJson(
      <String, dynamic>{'name': 'Test-Name', 'status': 1, 'weight': '1000'},
    );
    late NoDelegationStatsException delegationException;

    setUp(() async {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      delegationException = NoDelegationStatsException();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillar);
      when(
        () => mockPillar.getDelegatedPillar(any()),
      ).thenAnswer((_) async => delegationInfo);

      delegationStatsBloc = DelegationStatsBloc(
        zenon: mockZenon,
      );
    });

    test('initial status is correct', () {
      expect(delegationStatsBloc.state, const FetchInitial<DelegationInfo>());
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const FetchInitial<DelegationInfo> initialState =
            FetchInitial<DelegationInfo>();

        final Map<String, dynamic>? serialized = delegationStatsBloc.toJson(
          initialState,
        );
        final FetchState<DelegationInfo> deserialized = delegationStatsBloc
            .fromJson(
              serialized!,
            );
        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize success state', () {
        final FetchPopulated<DelegationInfo> successState =
            FetchPopulated<DelegationInfo>(
              data: delegationInfo,
            );

        final Map<String, dynamic>? serialized = delegationStatsBloc.toJson(
          successState,
        );
        final FetchState<DelegationInfo> deserialized = delegationStatsBloc
            .fromJson(
              serialized!,
            );
        expect(deserialized, equals(successState));
      });

      test('can (de)serialize failure state', () {
        final FetchFailure<DelegationInfo> failureState =
            FetchFailure<DelegationInfo>(
              exception: delegationException,
            );

        final Map<String, dynamic>? serialized = delegationStatsBloc.toJson(
          failureState,
        );
        final FetchState<DelegationInfo> deserialized = delegationStatsBloc
            .fromJson(
              serialized!,
            );
        expect(deserialized, equals(failureState));
      });
    });

    group('FetchRequestData event', () {
      blocTest<DelegationStatsBloc, FetchState<DelegationInfo>>(
        'sending FetchRequestData event calls getDelegatedPillar once',
        build: () => delegationStatsBloc,
        act: (DelegationStatsBloc bloc) =>
            bloc.add(FetchRequestData(address: emptyAddress)),
        verify: (_) {
          verify(
            () => mockZenon.embedded.pillar.getDelegatedPillar(
              emptyAddress,
            ),
          ).called(1);
        },
      );

      blocTest<DelegationStatsBloc, FetchState<DelegationInfo>>(
        'emits [failure] when getDelegatedPillar throws',
        setUp: () {
          when(
            () => mockPillar.getDelegatedPillar(
              any(),
            ),
          ).thenThrow(delegationException);
        },
        build: () => delegationStatsBloc,
        act: (DelegationStatsBloc bloc) =>
            bloc.add(FetchRequestData(address: emptyAddress)),
        expect: () => <FetchState<DelegationInfo>>[
          FetchFailure<DelegationInfo>(
            exception: delegationException,
          ),
        ],
      );

      blocTest<DelegationStatsBloc, FetchState<DelegationInfo>>(
        'emits [success] when getDelegatedPillar '
        'returns a DelegationInfo instance',
        build: () => delegationStatsBloc,
        act: (DelegationStatsBloc bloc) =>
            bloc.add(FetchRequestData(address: emptyAddress)),
        expect: () => <dynamic>[
          FetchPopulated<DelegationInfo>(
            data: delegationInfo,
          ),
        ],
      );
    });
  });
}
