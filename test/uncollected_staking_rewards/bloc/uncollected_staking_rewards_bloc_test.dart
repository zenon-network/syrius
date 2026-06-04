import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockStake extends Mock implements StakeApi {}

class MockUncollectedReward extends Mock implements UncollectedReward {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('UncollectedStakingRewardsBloc', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockStake mockStake;
    late UncollectedStakingRewardsBloc bloc;
    late MockUncollectedReward reward;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockStake = MockStake();
      reward = MockUncollectedReward();
      exception = FailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.stake).thenReturn(mockStake);
      when(() => reward.toJson()).thenReturn(<String, dynamic>{
        'znnAmount': '0',
        'qsrAmount': '1',
      });
      when(
        () => mockStake.getUncollectedReward(any()),
      ).thenAnswer((_) async => reward);

      bloc = UncollectedStakingRewardsBloc(zenon: mockZenon);
    });

    test('initial state is FetchInitial', () {
      expect(bloc.state, const FetchInitial<UncollectedReward>());
    });

    blocTest<UncollectedStakingRewardsBloc, FetchState<UncollectedReward>>(
      'calls getUncollectedReward once and emits populated state',
      build: () => bloc,
      act: (UncollectedStakingRewardsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      verify: (_) {
        verify(() => mockStake.getUncollectedReward(emptyAddress)).called(1);
      },
      expect: () => <FetchState<UncollectedReward>>[
        FetchPopulated<UncollectedReward>(data: reward),
      ],
    );

    blocTest<UncollectedStakingRewardsBloc, FetchState<UncollectedReward>>(
      'emits failure when getUncollectedReward throws',
      setUp: () {
        when(() => mockStake.getUncollectedReward(any())).thenThrow(exception);
      },
      build: () => bloc,
      act: (UncollectedStakingRewardsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<UncollectedReward>>[
        FetchFailure<UncollectedReward>(exception: exception),
      ],
    );
  });
}
