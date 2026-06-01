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
  });
}
