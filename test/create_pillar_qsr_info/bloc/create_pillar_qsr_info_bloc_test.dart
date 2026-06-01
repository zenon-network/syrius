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

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('CreatePillarQsrInfoBloc', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    late CreatePillarQsrInfoBloc bloc;
    late CreatePillarQsrInfoData data;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      data = CreatePillarQsrInfoData(
        cost: BigInt.from(1000),
        deposit: BigInt.from(500),
      );

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillar);
      when(() => mockPillar.getDepositedQsr(any()))
          .thenAnswer((_) async => data.deposit);
      when(() => mockPillar.getQsrRegistrationCost())
          .thenAnswer((_) async => data.cost);

      bloc = CreatePillarQsrInfoBloc(zenon: mockZenon);
    });

    test('initial state is FetchInitial', () {
      expect(bloc.state, const FetchInitial<CreatePillarQsrInfoData>());
    });

    blocTest<CreatePillarQsrInfoBloc, FetchState<CreatePillarQsrInfoData>>(
      'calls pillar methods once and emits populated state',
      build: () => bloc,
      act: (CreatePillarQsrInfoBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      verify: (_) {
        verify(() => mockPillar.getDepositedQsr(emptyAddress)).called(1);
        verify(() => mockPillar.getQsrRegistrationCost()).called(1);
      },
      expect: () => <FetchState<CreatePillarQsrInfoData>>[
        FetchPopulated<CreatePillarQsrInfoData>(data: data),
      ],
    );

    blocTest<CreatePillarQsrInfoBloc, FetchState<CreatePillarQsrInfoData>>(
      'emits failure when dependency throws',
      setUp: () {
        when(() => mockPillar.getDepositedQsr(any()))
            .thenThrow(FailureException());
      },
      build: () => bloc,
      act: (CreatePillarQsrInfoBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<FetchFailure<CreatePillarQsrInfoData>>(),
      ],
    );
  });
}
