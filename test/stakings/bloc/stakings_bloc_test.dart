import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockStakeApi extends Mock implements StakeApi {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('StakingsBloc', () {
    const int pageSize = 2;
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockStakeApi mockStakeApi;
    late StakingsBloc bloc;
    late StakeEntry stakeEntry;
    late StakeList stakeList;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockStakeApi = MockStakeApi();
      stakeEntry = StakeEntry(
        amount: BigInt.one,
        weightedAmount: BigInt.one,
        startTimestamp: 123,
        expirationTimestamp: 321,
        address: emptyAddress,
        id: emptyHash,
      );
      stakeList = StakeList(
        totalAmount: BigInt.one,
        totalWeightedAmount: BigInt.one,
        count: 1,
        list: <StakeEntry>[stakeEntry],
      );

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.stake).thenReturn(mockStakeApi);
      when(
        () => mockStakeApi.getEntriesByAddress(
          any(),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => stakeList);

      bloc = StakingsBloc(zenon: mockZenon, pageSize: pageSize);
    });

    test('initial state is initial', () {
      expect(bloc.state, const InfiniteListState<StakeEntry>.initial());
    });

    blocTest<StakingsBloc, InfiniteListState<StakeEntry>>(
      'requested emits success and calls api once',
      build: () => bloc,
      act: (StakingsBloc bloc) =>
          bloc.add(InfiniteListRequested(address: emptyAddress)),
      verify: (_) {
        verify(
          () => mockStakeApi.getEntriesByAddress(
            emptyAddress,
            pageIndex: 0,
            pageSize: pageSize,
          ),
        ).called(1);
      },
      expect: () => <InfiniteListState<StakeEntry>>[
        InfiniteListState<StakeEntry>(
          status: InfiniteListStatus.success,
          data: <StakeEntry>[stakeEntry],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<StakingsBloc, InfiniteListState<StakeEntry>>(
      'requested emits failure when api throws',
      setUp: () {
        when(
          () => mockStakeApi.getEntriesByAddress(
            any(),
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (StakingsBloc bloc) =>
          bloc.add(InfiniteListRequested(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<InfiniteListState<StakeEntry>>().having(
          (InfiniteListState<StakeEntry> s) => s.status,
          'status',
          InfiniteListStatus.failure,
        ),
      ],
    );
  });
}
