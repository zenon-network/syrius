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

class MockUncollectedReward extends Mock implements UncollectedReward {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('UncollectedPillarRewardsBloc', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    late UncollectedPillarRewardsBloc bloc;
    late MockUncollectedReward reward;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      reward = MockUncollectedReward();
      exception = FailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillar);
      when(() => reward.toJson()).thenReturn(<String, dynamic>{
        'znnAmount': '1',
        'qsrAmount': '1',
      });
      when(
        () => mockPillar.getUncollectedReward(any()),
      ).thenAnswer((_) async => reward);

      bloc = UncollectedPillarRewardsBloc(zenon: mockZenon);
    });

    test('initial state is FetchInitial', () {
      expect(bloc.state, const FetchInitial<UncollectedReward>());
    });

    blocTest<UncollectedPillarRewardsBloc, FetchState<UncollectedReward>>(
      'calls getUncollectedReward once and emits populated state',
      build: () => bloc,
      act: (UncollectedPillarRewardsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      verify: (_) {
        verify(() => mockPillar.getUncollectedReward(emptyAddress)).called(1);
      },
      expect: () => <FetchState<UncollectedReward>>[
        FetchPopulated<UncollectedReward>(data: reward),
      ],
    );

    blocTest<UncollectedPillarRewardsBloc, FetchState<UncollectedReward>>(
      'emits failure when getUncollectedReward throws',
      setUp: () {
        when(() => mockPillar.getUncollectedReward(any())).thenThrow(exception);
      },
      build: () => bloc,
      act: (UncollectedPillarRewardsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<UncollectedReward>>[
        FetchFailure<UncollectedReward>(exception: exception),
      ],
    );
  });
}
