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

class MockRewardHistoryList extends Mock implements RewardHistoryList {}

class MockRewardHistoryEntry extends Mock implements RewardHistoryEntry {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('StakingRewardsHistoryBloc', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockStake mockStake;
    late StakingRewardsHistoryBloc bloc;
    late MockRewardHistoryList rewardHistoryList;
    late MockRewardHistoryEntry rewardEntry;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockStake = MockStake();
      rewardHistoryList = MockRewardHistoryList();
      rewardEntry = MockRewardHistoryEntry();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.stake).thenReturn(mockStake);
      when(
        () => rewardHistoryList.list,
      ).thenReturn(<RewardHistoryEntry>[rewardEntry]);
      when(() => rewardHistoryList.toJson()).thenReturn(<String, dynamic>{
        'count': 1,
        'list': <Map<String, dynamic>>[
          <String, dynamic>{
            'epoch': 1,
            'znnAmount': '0',
            'qsrAmount': '1',
          },
        ],
      });
      when(() => rewardEntry.qsrAmount).thenReturn(BigInt.one);
      when(
        () => mockStake.getFrontierRewardByPage(
          any(),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => rewardHistoryList);

      bloc = StakingRewardsHistoryBloc(zenon: mockZenon);
    });

    test('initial state is FetchInitial', () {
      expect(bloc.state, const FetchInitial<RewardHistoryList>());
    });

    blocTest<StakingRewardsHistoryBloc, FetchState<RewardHistoryList>>(
      'calls getFrontierRewardByPage once and emits populated state',
      build: () => bloc,
      act: (StakingRewardsHistoryBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      verify: (_) {
        verify(
          () => mockStake.getFrontierRewardByPage(
            emptyAddress,
            pageSize: any(named: 'pageSize'),
          ),
        ).called(1);
      },
      expect: () => <FetchState<RewardHistoryList>>[
        FetchPopulated<RewardHistoryList>(data: rewardHistoryList),
      ],
    );

    blocTest<StakingRewardsHistoryBloc, FetchState<RewardHistoryList>>(
      'emits NoRewardsLastWeekException when all entries are zero',
      setUp: () {
        when(() => rewardEntry.qsrAmount).thenReturn(BigInt.zero);
      },
      build: () => bloc,
      act: (StakingRewardsHistoryBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<FetchFailure<RewardHistoryList>>().having(
          (FetchFailure<RewardHistoryList> state) => state.exception,
          'exception',
          isA<NoRewardsLastWeekException>(),
        ),
      ],
    );
  });
}
