import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockSentinel extends Mock implements SentinelApi {}

class MockUncollectedReward extends Mock implements UncollectedReward {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('UncollectedSentinelRewardsBloc', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late UncollectedSentinelRewardsBloc bloc;
    late MockUncollectedReward reward;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      reward = MockUncollectedReward();
      exception = FailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.sentinel).thenReturn(mockSentinel);
      when(() => reward.toJson()).thenReturn(<String, dynamic>{
        'znnAmount': '1',
        'qsrAmount': '1',
      });
      when(
        () => mockSentinel.getUncollectedReward(any()),
      ).thenAnswer((_) async => reward);

      bloc = UncollectedSentinelRewardsBloc(zenon: mockZenon);
    });

    test('initial state is FetchInitial', () {
      expect(bloc.state, const FetchInitial<UncollectedReward>());
    });

    blocTest<UncollectedSentinelRewardsBloc, FetchState<UncollectedReward>>(
      'calls getUncollectedReward once and emits populated state',
      build: () => bloc,
      act: (UncollectedSentinelRewardsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      verify: (_) {
        verify(() => mockSentinel.getUncollectedReward(emptyAddress)).called(1);
      },
      expect: () => <FetchState<UncollectedReward>>[
        FetchPopulated<UncollectedReward>(data: reward),
      ],
    );

    blocTest<UncollectedSentinelRewardsBloc, FetchState<UncollectedReward>>(
      'emits failure when getUncollectedReward throws',
      setUp: () {
        when(() => mockSentinel.getUncollectedReward(any()))
            .thenThrow(exception);
      },
      build: () => bloc,
      act: (UncollectedSentinelRewardsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<UncollectedReward>>[
        FetchFailure<UncollectedReward>(exception: exception),
      ],
    );
  });
}
