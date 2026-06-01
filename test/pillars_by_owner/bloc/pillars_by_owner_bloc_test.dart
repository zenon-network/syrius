import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillar extends Mock implements PillarApi {}

class FakeAddress extends Fake implements Address {}

class MockPillarInfo extends Mock implements PillarInfo {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('PillarsByOwnerBloc', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    late PillarsByOwnerBloc bloc;
    late MockPillarInfo pillarInfo;
    late List<PillarInfo> data;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      pillarInfo = MockPillarInfo();
      data = <PillarInfo>[pillarInfo];
      exception = FailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillar);
      when(() => pillarInfo.toJson()).thenReturn(<String, dynamic>{
        'name': 'pillar-name',
        'rank': 1,
        'type': 0,
        'ownerAddress': emptyAddress.toString(),
        'producerAddress': emptyAddress.toString(),
        'withdrawAddress': emptyAddress.toString(),
        'isRevocable': false,
        'revokeCooldown': 0,
        'revokeTimestamp': 0,
        'currentStats': <String, dynamic>{},
        'weight': '1',
        'giveMomentumRewardPercentage': 0,
        'giveDelegateRewardPercentage': 0,
      });
      when(() => mockPillar.getByOwner(any())).thenAnswer((_) async => data);

      bloc = PillarsByOwnerBloc(zenon: mockZenon);
    });

    test('initial state is FetchInitial', () {
      expect(bloc.state, const FetchInitial<List<PillarInfo>>());
    });

    blocTest<PillarsByOwnerBloc, FetchState<List<PillarInfo>>>(
      'calls getByOwner once and emits populated state',
      build: () => bloc,
      act: (PillarsByOwnerBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      verify: (_) {
        verify(() => mockPillar.getByOwner(emptyAddress)).called(1);
      },
      expect: () => <FetchState<List<PillarInfo>>>[
        FetchPopulated<List<PillarInfo>>(data: data),
      ],
    );

    blocTest<PillarsByOwnerBloc, FetchState<List<PillarInfo>>>(
      'emits failure when getByOwner throws',
      setUp: () {
        when(() => mockPillar.getByOwner(any())).thenThrow(exception);
      },
      build: () => bloc,
      act: (PillarsByOwnerBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<List<PillarInfo>>>[
        FetchFailure<List<PillarInfo>>(exception: exception),
      ],
    );
  });
}
