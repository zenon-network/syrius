import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/infinite_list/infinite_list_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class FakeAddress extends Fake implements Address {}

class TestInfiniteListBloc extends InfiniteListBloc<int> {
  TestInfiniteListBloc({
    required super.zenon,
    required this.paginationFetchCallback,
    super.pageSize = 2,
  }) : super(
         fromJsonT: (Object? value) => value! as int,
         toJsonT: (int value) => value,
       );

  final Future<List<int>> Function(
    Address? address,
    int pageIndex,
    int pageSize,
  )
  paginationFetchCallback;

  @override
  Future<List<int>> paginationFetch({
    required Address? address,
    required int pageIndex,
    required int pageSize,
  }) => paginationFetchCallback(address, pageIndex, pageSize);
}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('InfiniteListBloc', () {
    late MockZenon mockZenon;

    setUp(() {
      mockZenon = MockZenon();
    });

    test('initial state is correct', () {
      final TestInfiniteListBloc bloc = TestInfiniteListBloc(
        zenon: mockZenon,
        paginationFetchCallback: (_, _, _) async => <int>[1],
      );
      expect(bloc.state, const InfiniteListState<int>.initial());
    });

    blocTest<TestInfiniteListBloc, InfiniteListState<int>>(
      'requested emits success with fetched data',
      build: () => TestInfiniteListBloc(
        zenon: mockZenon,
        paginationFetchCallback: (_, _, _) async => <int>[1, 2],
      ),
      act: (TestInfiniteListBloc bloc) =>
          bloc.add(InfiniteListRequested(address: emptyAddress)),
      expect: () => <InfiniteListState<int>>[
        const InfiniteListState<int>(
          status: InfiniteListStatus.success,
          data: <int>[1, 2],
        ),
      ],
    );

    blocTest<TestInfiniteListBloc, InfiniteListState<int>>(
      'more requested appends data',
      build: () => TestInfiniteListBloc(
        zenon: mockZenon,
        paginationFetchCallback: (_, int pageIndex, _) async {
          if (pageIndex == 0) {
            return <int>[1, 2];
          }
          return <int>[3];
        },
      ),
      act: (TestInfiniteListBloc bloc) async {
        bloc.add(InfiniteListRequested(address: emptyAddress));
        await Future<void>.delayed(Duration.zero);
        bloc.add(InfiniteListMoreRequested(address: emptyAddress));
      },
      expect: () => <InfiniteListState<int>>[
        const InfiniteListState<int>(
          status: InfiniteListStatus.success,
          data: <int>[1, 2],
        ),
        const InfiniteListState<int>(
          status: InfiniteListStatus.success,
          data: <int>[1, 2, 3],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<TestInfiniteListBloc, InfiniteListState<int>>(
      'refresh requested emits initial then success',
      build: () => TestInfiniteListBloc(
        zenon: mockZenon,
        paginationFetchCallback: (_, _, _) async => <int>[9],
      ),
      act: (TestInfiniteListBloc bloc) =>
          bloc.add(InfiniteListRefreshRequested(address: emptyAddress)),
      expect: () => <InfiniteListState<int>>[
        const InfiniteListState<int>.initial(),
        const InfiniteListState<int>(
          status: InfiniteListStatus.success,
          data: <int>[9],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<TestInfiniteListBloc, InfiniteListState<int>>(
      'requested emits failure when fetch throws',
      build: () => TestInfiniteListBloc(
        zenon: mockZenon,
        paginationFetchCallback: (_, _, _) async => throw Exception('err'),
      ),
      act: (TestInfiniteListBloc bloc) =>
          bloc.add(InfiniteListRequested(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<InfiniteListState<int>>()
            .having(
              (InfiniteListState<int> s) => s.status,
              'status',
              InfiniteListStatus.failure,
            )
            .having(
              (InfiniteListState<int> s) => s.error,
              'error',
              isA<FailureException>(),
            ),
      ],
    );

    test(
      'back-to-back refreshes within throttle window do not strand state in '
      'initial and track isLoadingListenable accurately',
      () async {
        final Completer<List<int>> secondRefreshCompleter =
            Completer<List<int>>();
        final Completer<void> secondRefreshStarted = Completer<void>();
        int fetchCount = 0;

        final TestInfiniteListBloc bloc = TestInfiniteListBloc(
          zenon: mockZenon,
          paginationFetchCallback: (_, _, _) {
            fetchCount++;
            if (fetchCount == 1) {
              return Future<List<int>>.value(<int>[1]);
            }
            if (!secondRefreshStarted.isCompleted) {
              secondRefreshStarted.complete();
            }
            return secondRefreshCompleter.future;
          },
        );
        addTearDown(bloc.close);

        expect(bloc.isLoadingListenable.value, isFalse);

        // First request completes quickly.
        final Future<InfiniteListState<int>> firstSuccess = bloc.stream
            .firstWhere(
              (InfiniteListState<int> s) =>
                  s.status == InfiniteListStatus.success,
            )
            .timeout(const Duration(seconds: 5));
        bloc.add(InfiniteListRequested(address: emptyAddress));
        await firstSuccess;
        expect(bloc.isLoadingListenable.value, isFalse);

        // Immediate refresh within the 100ms throttle window must NOT be
        // dropped and must expose loading until completion.
        bloc.add(InfiniteListRefreshRequested(address: emptyAddress));
        await secondRefreshStarted.future.timeout(const Duration(seconds: 5));
        expect(bloc.state.status, InfiniteListStatus.initial);
        expect(bloc.isLoadingListenable.value, isTrue);

        final Future<InfiniteListState<int>> secondSuccess = bloc.stream
            .firstWhere(
              (InfiniteListState<int> s) =>
                  s.status == InfiniteListStatus.success,
            )
            .timeout(const Duration(seconds: 5));
        secondRefreshCompleter.complete(<int>[2]);
        final InfiniteListState<int> finalState = await secondSuccess;

        expect(finalState.data, equals(<int>[2]));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.isLoadingListenable.value, isFalse);
      },
    );

    test(
      'discards superseded initial fetch for an older address after refresh',
      () async {
        final Address addressA = Address.fromPublicKey(
          List<int>.filled(32, 1),
        );
        final Address addressB = Address.fromPublicKey(
          List<int>.filled(32, 2),
        );
        final Completer<List<int>> fetchA = Completer<List<int>>();
        final Completer<void> fetchAStarted = Completer<void>();
        final Completer<List<int>> fetchB = Completer<List<int>>();
        final Completer<void> fetchBStarted = Completer<void>();

        final TestInfiniteListBloc bloc = TestInfiniteListBloc(
          zenon: mockZenon,
          paginationFetchCallback: (Address? address, _, _) {
            if (address == addressA) {
              if (!fetchAStarted.isCompleted) {
                fetchAStarted.complete();
              }
              return fetchA.future;
            }
            if (!fetchBStarted.isCompleted) {
              fetchBStarted.complete();
            }
            return fetchB.future;
          },
        );
        addTearDown(bloc.close);

        bloc.add(InfiniteListRequested(address: addressA));
        await fetchAStarted.future.timeout(const Duration(seconds: 5));
        expect(bloc.isLoadingListenable.value, isTrue);

        // Switching address dispatches a refresh while A is still pending.
        bloc.add(InfiniteListRefreshRequested(address: addressB));
        await fetchBStarted.future.timeout(const Duration(seconds: 5));
        expect(bloc.isLoadingListenable.value, isTrue);

        final Future<InfiniteListState<int>> bSuccess = bloc.stream
            .firstWhere(
              (InfiniteListState<int> s) =>
                  s.status == InfiniteListStatus.success,
            )
            .timeout(const Duration(seconds: 5));
        fetchB.complete(<int>[20]);
        final InfiniteListState<int> stateAfterB = await bSuccess;
        expect(stateAfterB.data, equals(<int>[20]));
        await Future<void>.delayed(Duration.zero);
        // Loading clears as soon as the latest request finishes, even though
        // discarded fetch A is still pending.
        expect(bloc.isLoadingListenable.value, isFalse);

        // Late completion of stale fetch A must not overwrite B's list.
        fetchA.complete(<int>[10]);
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.data, equals(<int>[20]));
        expect(bloc.isLoadingListenable.value, isFalse);
      },
    );

    test(
      'clears isLoadingListenable as soon as replacement refresh completes '
      'even while discarded refresh is still pending',
      () async {
        final Completer<List<int>> refreshA = Completer<List<int>>();
        final Completer<void> refreshAStarted = Completer<void>();
        final Completer<List<int>> refreshB = Completer<List<int>>();
        final Completer<void> refreshBStarted = Completer<void>();
        int callCount = 0;

        final TestInfiniteListBloc bloc = TestInfiniteListBloc(
          zenon: mockZenon,
          paginationFetchCallback: (_, _, _) {
            callCount++;
            if (callCount == 1) {
              if (!refreshAStarted.isCompleted) {
                refreshAStarted.complete();
              }
              return refreshA.future;
            }
            if (!refreshBStarted.isCompleted) {
              refreshBStarted.complete();
            }
            return refreshB.future;
          },
        );
        addTearDown(bloc.close);

        bloc.add(InfiniteListRefreshRequested(address: emptyAddress));
        await refreshAStarted.future.timeout(const Duration(seconds: 5));
        expect(bloc.isLoadingListenable.value, isTrue);

        bloc.add(InfiniteListRefreshRequested(address: emptyAddress));
        await refreshBStarted.future.timeout(const Duration(seconds: 5));
        expect(bloc.isLoadingListenable.value, isTrue);

        final Future<InfiniteListState<int>> bSuccess = bloc.stream
            .firstWhere(
              (InfiniteListState<int> s) =>
                  s.status == InfiniteListStatus.success,
            )
            .timeout(const Duration(seconds: 5));
        refreshB.complete(<int>[99]);
        await bSuccess;
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.data, equals(<int>[99]));
        expect(bloc.isLoadingListenable.value, isFalse);

        // Discarded refresh A completing later must not touch state or loading.
        refreshA.complete(<int>[1]);
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.data, equals(<int>[99]));
        expect(bloc.isLoadingListenable.value, isFalse);
      },
    );

    test(
      'ignores InfiniteListMoreRequested for a stale address after switching '
      'addresses',
      () async {
        final Address addressA = Address.fromPublicKey(
          List<int>.filled(32, 1),
        );
        final Address addressB = Address.fromPublicKey(
          List<int>.filled(32, 2),
        );
        int moreCallsForA = 0;

        final TestInfiniteListBloc bloc = TestInfiniteListBloc(
          zenon: mockZenon,
          paginationFetchCallback: (Address? address, int pageIndex, _) async {
            if (address == addressA && pageIndex > 0) {
              moreCallsForA++;
              return <int>[101, 102];
            }
            if (address == addressB && pageIndex == 0) {
              return <int>[201, 202];
            }
            return <int>[1, 2];
          },
        );
        addTearDown(bloc.close);

        final Future<InfiniteListState<int>> bLoaded = bloc.stream
            .firstWhere(
              (InfiniteListState<int> s) =>
                  s.status == InfiniteListStatus.success &&
                  s.data?.first == 201,
            )
            .timeout(const Duration(seconds: 5));
        bloc.add(InfiniteListRefreshRequested(address: addressB));
        await bLoaded;

        // A queued pagination request for the old address must be ignored.
        bloc.add(InfiniteListMoreRequested(address: addressA));
        await Future<void>.delayed(Duration.zero);

        expect(moreCallsForA, 0);
        expect(bloc.state.data, equals(<int>[201, 202]));
      },
    );

    test(
      'discards in-flight InfiniteListMoreRequested when superseded by refresh',
      () async {
        final Address addressA = Address.fromPublicKey(
          List<int>.filled(32, 1),
        );
        final Address addressB = Address.fromPublicKey(
          List<int>.filled(32, 2),
        );
        final Completer<List<int>> moreForA = Completer<List<int>>();
        final Completer<void> moreForAStarted = Completer<void>();

        final TestInfiniteListBloc bloc = TestInfiniteListBloc(
          zenon: mockZenon,
          paginationFetchCallback: (Address? address, int pageIndex, _) {
            if (address == addressA && pageIndex == 0) {
              return Future<List<int>>.value(<int>[1, 2]);
            }
            if (address == addressA && pageIndex == 1) {
              if (!moreForAStarted.isCompleted) {
                moreForAStarted.complete();
              }
              return moreForA.future;
            }
            return Future<List<int>>.value(<int>[20, 21]);
          },
        );
        addTearDown(bloc.close);

        final Future<InfiniteListState<int>> aLoaded = bloc.stream
            .firstWhere(
              (InfiniteListState<int> s) =>
                  s.status == InfiniteListStatus.success,
            )
            .timeout(const Duration(seconds: 5));
        bloc.add(InfiniteListRequested(address: addressA));
        await aLoaded;

        // Start loading page 1 for address A, then switch to address B.
        bloc.add(InfiniteListMoreRequested(address: addressA));
        await moreForAStarted.future.timeout(const Duration(seconds: 5));

        final Future<InfiniteListState<int>> bLoaded = bloc.stream
            .firstWhere(
              (InfiniteListState<int> s) =>
                  s.status == InfiniteListStatus.success && s.data?.first == 20,
            )
            .timeout(const Duration(seconds: 5));
        bloc.add(InfiniteListRefreshRequested(address: addressB));
        await bLoaded;

        // Completing the stale page-1 fetch for A must not modify B's list.
        moreForA.complete(<int>[3, 4]);
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.data, equals(<int>[20, 21]));
      },
    );

    test(
      'allows null-address pagination after a refresh with an address',
      () async {
        final Address selected = Address.fromPublicKey(
          List<int>.filled(32, 3),
        );
        final TestInfiniteListBloc bloc = TestInfiniteListBloc(
          zenon: mockZenon,
          paginationFetchCallback: (_, int pageIndex, _) async {
            return pageIndex == 0 ? <int>[1, 2] : <int>[3];
          },
        );
        addTearDown(bloc.close);

        final Future<InfiniteListState<int>> firstPage = bloc.stream
            .firstWhere(
              (InfiniteListState<int> s) =>
                  s.status == InfiniteListStatus.success,
            )
            .timeout(const Duration(seconds: 5));
        bloc.add(InfiniteListRefreshRequested(address: selected));
        await firstPage;

        final Future<InfiniteListState<int>> secondPage = bloc.stream
            .firstWhere(
              (InfiniteListState<int> s) =>
                  s.status == InfiniteListStatus.success &&
                  (s.data?.length ?? 0) == 3,
            )
            .timeout(const Duration(seconds: 5));
        bloc.add(const InfiniteListMoreRequested());
        final InfiniteListState<int> updated = await secondPage;

        expect(updated.data, equals(<int>[1, 2, 3]));
      },
    );

    test(
      'discards load-more that started while a first-page fetch was in flight '
      'and completed after it',
      () async {
        final Completer<List<int>> page0Completer = Completer<List<int>>();
        final Completer<void> page0Started = Completer<void>();
        final Completer<List<int>> moreCompleter = Completer<List<int>>();
        final Completer<void> moreStarted = Completer<void>();

        final TestInfiniteListBloc bloc = TestInfiniteListBloc(
          zenon: mockZenon,
          paginationFetchCallback: (_, int pageIndex, _) {
            if (!page0Started.isCompleted) {
              page0Started.complete();
              return page0Completer.future;
            }
            if (!moreStarted.isCompleted) {
              moreStarted.complete();
            }
            return moreCompleter.future;
          },
        );
        addTearDown(bloc.close);

        // Start a first-page fetch (captures requestId == 1).
        bloc.add(InfiniteListRequested(address: emptyAddress));
        await page0Started.future.timeout(const Duration(seconds: 5));

        // Start a load-more while the first-page fetch is still in flight
        // (same requestId == 1, snapshotData == null).
        bloc.add(InfiniteListMoreRequested(address: emptyAddress));
        await moreStarted.future.timeout(const Duration(seconds: 5));

        // First-page fetch finishes and populates fresh data.
        final Future<InfiniteListState<int>> page0Done = bloc.stream
            .firstWhere(
              (InfiniteListState<int> s) =>
                  s.status == InfiniteListStatus.success,
            )
            .timeout(const Duration(seconds: 5));
        page0Completer.complete(<int>[10, 20]);
        await page0Done;

        // Completing the earlier load-more must not overwrite fresh page 0.
        moreCompleter.complete(<int>[99]);
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.data, equals(<int>[10, 20]));
      },
    );

    test(
      'keeps isLoadingMoreListenable true across overlapping load-more '
      'requests until all in-flight fetches finish',
      () async {
        final Completer<List<int>> more1 = Completer<List<int>>();
        final Completer<void> more1Started = Completer<void>();
        final Completer<List<int>> more2 = Completer<List<int>>();
        final Completer<void> more2Started = Completer<void>();
        int moreCalls = 0;

        final TestInfiniteListBloc bloc = TestInfiniteListBloc(
          zenon: mockZenon,
          paginationFetchCallback: (_, int pageIndex, _) {
            if (pageIndex == 0) {
              return Future<List<int>>.value(<int>[1, 2]);
            }
            moreCalls += 1;
            if (moreCalls == 1) {
              if (!more1Started.isCompleted) {
                more1Started.complete();
              }
              return more1.future;
            }
            if (!more2Started.isCompleted) {
              more2Started.complete();
            }
            return more2.future;
          },
        );
        addTearDown(bloc.close);

        final Future<InfiniteListState<int>> page0Loaded = bloc.stream
            .firstWhere(
              (InfiniteListState<int> s) =>
                  s.status == InfiniteListStatus.success,
            )
            .timeout(const Duration(seconds: 5));
        bloc.add(InfiniteListRequested(address: emptyAddress));
        await page0Loaded;
        expect(bloc.isLoadingMoreListenable.value, isFalse);

        bloc
          ..add(InfiniteListMoreRequested(address: emptyAddress))
          ..add(InfiniteListMoreRequested(address: emptyAddress));
        await more1Started.future.timeout(const Duration(seconds: 5));
        await more2Started.future.timeout(const Duration(seconds: 5));
        expect(bloc.isLoadingMoreListenable.value, isTrue);

        // First load-more finishes while the second is still pending.
        more1.complete(<int>[3, 4]);
        await Future<void>.delayed(Duration.zero);
        expect(bloc.isLoadingMoreListenable.value, isTrue);

        // Once the second finishes too, isLoadingMoreListenable clears.
        more2.complete(<int>[5, 6]);
        await Future<void>.delayed(Duration.zero);
        expect(bloc.isLoadingMoreListenable.value, isFalse);
      },
    );
  });
}
