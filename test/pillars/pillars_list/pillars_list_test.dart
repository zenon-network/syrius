import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars.dart';
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

  group('LatestTransactionsBloc', () {
    const int kTestPageSize = 1;
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillar mockPillar;
    late PillarsListBloc pillarsListBloc;
    late PillarInfoList pillarInfoList;
    late List<PillarInfo> pillarInfo;
    late FailureException exception;

    setUp(() async {

      final Map<String, int> pillarEpochJson = <String, int> {
        'producedMomentums': 100,
        'expectedMomentums': 150,
      };

      final Map<String, dynamic> pillarInfoJson = <String, dynamic> {
        'name': 'PillarOne',
        'rank': 1,
        'type': 2,
        'ownerAddress': emptyAddress.toString(),
        'producerAddress': emptyAddress.toString(),
        'withdrawAddress': emptyAddress.toString(),
        'giveMomentumRewardPercentage': 1,
        'giveDelegateRewardPercentage': 2,
        'isRevocable': true,
        'revokeCooldown': 86400,
        'revokeTimestamp': 1650000000,
        'currentStats': pillarEpochJson,
        'weight': '500000000000000000000',
        'producedMomentums': 100,
        'expectedMomentums': 150,
      };

      final Map<String, dynamic> pillarInfoListJson = <String, dynamic> {
        'count': 1,
        'list': <Map<String, dynamic>>[pillarInfoJson],
      };

      pillarInfo = <PillarInfo>[
        PillarInfo.fromJson(pillarInfoJson),
      ];

      pillarInfoList = PillarInfoList.fromJson(pillarInfoListJson);

      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillar = MockPillar();
      exception = FailureException();
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillar);
      when(
            () => mockPillar.getAll(
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => pillarInfoList);

      pillarsListBloc = PillarsListBloc(
        zenon: mockZenon,
        pageSize: 1,
      );
    });

    tearDown(() {
      pillarsListBloc.close();
    });

    test('initial state is correct', () {
      expect(
        pillarsListBloc.state.status,
        InfiniteListStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        final InfiniteListState<PillarInfo> initialState =
        InfiniteListState<PillarInfo>.initial();

        final Map<String, dynamic>? serialized = pillarsListBloc.toJson(
          initialState,
        );
        final InfiniteListState<PillarInfo>? deserialized =
        pillarsListBloc.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize success state', () {
        final InfiniteListState<PillarInfo> successState =
        InfiniteListState<PillarInfo>(
          status: InfiniteListStatus.success,
          data: pillarInfo,
        );

        final Map<String, dynamic>? serialized = pillarsListBloc.toJson(
          successState,
        );
        final InfiniteListState<PillarInfo>? deserialized =
        pillarsListBloc.fromJson(
          serialized!,
        );
        expect(deserialized, isA<InfiniteListState<PillarInfo>>());
        expect(deserialized!.status, equals(InfiniteListStatus.success));
        expect(deserialized.data, isA<List<PillarInfo>?>());
      });

      test('can (de)serialize failure state', () {
        final InfiniteListState<PillarInfo> failureState =
        InfiniteListState<PillarInfo>(
          status: InfiniteListStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized = pillarsListBloc.toJson(
          failureState,
        );
        final InfiniteListState<PillarInfo>? deserialized =
        pillarsListBloc.fromJson(
          serialized!,
        );
        expect(deserialized, equals(failureState));
      });
    });

    blocTest<PillarsListBloc, InfiniteListState<PillarInfo>>(
      'emits [success] with data is successfully fetched',
      build: () => pillarsListBloc,
      act: (PillarsListBloc cubit) => cubit.add(
        InfiniteListRequested(
          address: emptyAddress,
        ),
      ),
      expect: () {
        final List<PillarInfo> data = pillarInfo;

        final bool hasReachedMax = data.length < kTestPageSize;

        return <InfiniteListState<PillarInfo>>[
          InfiniteListState<PillarInfo>(
            status: InfiniteListStatus.success,
            data: data,
            hasReachedMax: hasReachedMax,
          ),
        ];
      },
    );

    blocTest<PillarsListBloc, InfiniteListState<PillarInfo>>(
      'emits [failure] on fetch failure',
      setUp: () {
        when(
              () => mockPillar.getAll(
                pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenThrow(exception);
      },
      build: () => pillarsListBloc,
      act: (PillarsListBloc cubit) => cubit.add(
        InfiniteListRequested(
          address: emptyAddress,
        ),
      ),
      expect: () => <InfiniteListState<PillarInfo>>[
        InfiniteListState<PillarInfo>(
          status: InfiniteListStatus.failure,
          error: exception,
        ),
      ],
    );

    blocTest<PillarsListBloc, InfiniteListState<PillarInfo>>(
      'emits [initial, success] when refresh is requested',
      build: () => pillarsListBloc,
      act: (PillarsListBloc cubit) => cubit.add(
        InfiniteListRefreshRequested(
          address: emptyAddress,
        ),
      ),
      expect: () {
        final List<PillarInfo> data = pillarInfo;

        final bool hasReachedMax = data.length < kTestPageSize;

        return <InfiniteListState<PillarInfo>>[
          InfiniteListState<PillarInfo>.initial(),
          InfiniteListState<PillarInfo>(
            status: InfiniteListStatus.success,
            data: data,
            hasReachedMax: hasReachedMax,
          ),
        ];
      },
    );

    blocTest<PillarsListBloc, InfiniteListState<PillarInfo>>(
      'emits [initial, success, success] when more transactions are requested',
      build: () => pillarsListBloc,
      act: (PillarsListBloc bloc) async {
        bloc
            .add(
          InfiniteListRefreshRequested(
            address: emptyAddress,
          ),
        );

        // New events sent immediately one after the other will be dropped
        await Future<void>.delayed(const Duration(milliseconds: 200));

        bloc.add(
          InfiniteListMoreRequested(
            address: emptyAddress,
          ),
        );
      },
      expect: () {
        final List<PillarInfo> data = pillarInfo;

        final bool hasReachedMax = data.length < kTestPageSize;

        return <InfiniteListState<PillarInfo>>[
          InfiniteListState<PillarInfo>.initial(),
          InfiniteListState<PillarInfo>(
            status: InfiniteListStatus.success,
            data: data,
            hasReachedMax: hasReachedMax,
          ),
          InfiniteListState<PillarInfo>(
            status: InfiniteListStatus.success,
            data: <PillarInfo>[
              ...data,
              ...data,
            ],
            hasReachedMax: hasReachedMax,
          ),
        ];
      },
    );
  });
}
