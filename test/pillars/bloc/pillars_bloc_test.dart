import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class MockPillarInfoList extends Mock implements PillarInfoList {}

class MockPillarInfo extends Mock implements PillarInfo {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('PillarsBloc', () {
    const int pageSize = 2;
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late MockPillarInfoList mockPillarInfoList;
    late PillarsBloc bloc;
    late MockPillarInfo pillarInfo;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockPillarInfoList = MockPillarInfoList();
      pillarInfo = MockPillarInfo();

      when(() => pillarInfo.toJson()).thenReturn(<String, dynamic>{
            'name': 'pillar-name',
            'rank': 1,
            'type': 0,
            'ownerAddress': emptyAddress.toString(),
            'producerAddress': emptyAddress.toString(),
            'withdrawAddress': emptyAddress.toString(),
            'isRevocable': false,
            'revokeCooldown': 0,
            'revokeTimestamp': 0,
            'currentStats': <String, dynamic>{},
            'weight': '1',
            'giveMomentumRewardPercentage': 0,
            'giveDelegateRewardPercentage': 0,
          });
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);
      when(() => mockPillarInfoList.list).thenReturn(<PillarInfo>[pillarInfo]);
      when(
        () => mockPillarApi.getAll(
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => mockPillarInfoList);

      bloc = PillarsBloc(zenon: mockZenon, pageSize: pageSize);
    });

    test('initial state is initial', () {
      expect(bloc.state, const InfiniteListState<PillarInfo>.initial());
    });

    blocTest<PillarsBloc, InfiniteListState<PillarInfo>>(
      'requested emits success and calls api once',
      build: () => bloc,
      act: (PillarsBloc bloc) =>
          bloc.add(InfiniteListRequested(address: emptyAddress)),
      verify: (_) {
        verify(
          () => mockPillarApi.getAll(
            pageIndex: 0,
            pageSize: pageSize,
          ),
        ).called(1);
      },
      expect: () => <InfiniteListState<PillarInfo>>[
        InfiniteListState<PillarInfo>(
          status: InfiniteListStatus.success,
          data: <PillarInfo>[pillarInfo],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<PillarsBloc, InfiniteListState<PillarInfo>>(
      'requested emits failure when api throws',
      setUp: () {
        when(
          () => mockPillarApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (PillarsBloc bloc) =>
          bloc.add(InfiniteListRequested(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<InfiniteListState<PillarInfo>>().having(
          (InfiniteListState<PillarInfo> s) => s.status,
          'status',
          InfiniteListStatus.failure,
        ),
      ],
    );
  });
}
