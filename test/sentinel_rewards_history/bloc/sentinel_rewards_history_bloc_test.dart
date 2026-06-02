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

class MockRewardHistoryList extends Mock implements RewardHistoryList {}

class MockRewardHistoryEntry extends Mock implements RewardHistoryEntry {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('SentinelRewardsHistoryBloc', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late SentinelRewardsHistoryBloc bloc;
    late MockRewardHistoryList rewardHistoryList;
    late MockRewardHistoryEntry rewardEntry;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      rewardHistoryList = MockRewardHistoryList();
      rewardEntry = MockRewardHistoryEntry();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.sentinel).thenReturn(mockSentinel);
      when(
        () => rewardHistoryList.list,
      ).thenReturn(<RewardHistoryEntry>[rewardEntry]);
      when(() => rewardHistoryList.toJson()).thenReturn(<String, dynamic>{
        'count': 1,
        'list': <Map<String, dynamic>>[
          <String, dynamic>{
            'epoch': 1,
            'znnAmount': '1',
            'qsrAmount': '0',
          },
        ],
      });
      when(() => rewardEntry.znnAmount).thenReturn(BigInt.one);
      when(() => rewardEntry.qsrAmount).thenReturn(BigInt.zero);
      when(
        () => mockSentinel.getFrontierRewardByPage(
          any(),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => rewardHistoryList);

      bloc = SentinelRewardsHistoryBloc(zenon: mockZenon);
    });

    test('initial state is FetchInitial', () {
      expect(bloc.state, const FetchInitial<RewardHistoryList>());
    });

    blocTest<SentinelRewardsHistoryBloc, FetchState<RewardHistoryList>>(
      'calls getFrontierRewardByPage once and emits populated state',
      build: () => bloc,
      act: (SentinelRewardsHistoryBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      verify: (_) {
        verify(
          () => mockSentinel.getFrontierRewardByPage(
            emptyAddress,
            pageSize: any(named: 'pageSize'),
          ),
        ).called(1);
      },
      expect: () => <FetchState<RewardHistoryList>>[
        FetchPopulated<RewardHistoryList>(data: rewardHistoryList),
      ],
    );

    blocTest<SentinelRewardsHistoryBloc, FetchState<RewardHistoryList>>(
      'emits populated state when only qsr rewards are present',
      setUp: () {
        when(() => rewardEntry.znnAmount).thenReturn(BigInt.zero);
        when(() => rewardEntry.qsrAmount).thenReturn(BigInt.one);
      },
      build: () => bloc,
      act: (SentinelRewardsHistoryBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<RewardHistoryList>>[
        FetchPopulated<RewardHistoryList>(data: rewardHistoryList),
      ],
    );

    blocTest<SentinelRewardsHistoryBloc, FetchState<RewardHistoryList>>(
      'emits NoRewardsLastWeekException when all entries are zero',
      setUp: () {
        when(() => rewardEntry.znnAmount).thenReturn(BigInt.zero);
        when(() => rewardEntry.qsrAmount).thenReturn(BigInt.zero);
      },
      build: () => bloc,
      act: (SentinelRewardsHistoryBloc bloc) =>
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
