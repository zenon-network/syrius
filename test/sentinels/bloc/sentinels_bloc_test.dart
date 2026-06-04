import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockSentinelApi extends Mock implements SentinelApi {}

class MockSentinelInfoList extends Mock implements SentinelInfoList {}

class MockSentinelInfo extends Mock implements SentinelInfo {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('SentinelsBloc', () {
    const int pageSize = 2;
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockSentinelApi mockSentinelApi;
    late MockSentinelInfoList mockSentinelInfoList;
    late SentinelsBloc bloc;
    late MockSentinelInfo sentinelInfo;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockSentinelApi = MockSentinelApi();
      mockSentinelInfoList = MockSentinelInfoList();
      sentinelInfo = MockSentinelInfo();

      when(() => sentinelInfo.toJson()).thenReturn(<String, dynamic>{
        'owner': emptyAddress.toString(),
        'registrationTimestamp': 1625132800,
        'isRevocable': true,
        'revokeCooldown': 1000,
        'active': true,
      });
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.sentinel).thenReturn(mockSentinelApi);
      when(
        () => mockSentinelInfoList.list,
      ).thenReturn(<SentinelInfo>[sentinelInfo]);
      when(
        () => mockSentinelApi.getAllActive(
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => mockSentinelInfoList);

      bloc = SentinelsBloc(zenon: mockZenon, pageSize: pageSize);
    });

    test('initial state is initial', () {
      expect(bloc.state, const InfiniteListState<SentinelInfo>.initial());
    });

    blocTest<SentinelsBloc, InfiniteListState<SentinelInfo>>(
      'requested emits success and calls api once',
      build: () => bloc,
      act: (SentinelsBloc bloc) =>
          bloc.add(InfiniteListRequested(address: emptyAddress)),
      verify: (_) {
        verify(
          () => mockSentinelApi.getAllActive(
            pageSize: pageSize,
          ),
        ).called(1);
      },
      expect: () => <InfiniteListState<SentinelInfo>>[
        InfiniteListState<SentinelInfo>(
          status: InfiniteListStatus.success,
          data: <SentinelInfo>[sentinelInfo],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<SentinelsBloc, InfiniteListState<SentinelInfo>>(
      'requested emits failure when api throws',
      setUp: () {
        when(
          () => mockSentinelApi.getAllActive(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (SentinelsBloc bloc) =>
          bloc.add(InfiniteListRequested(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<InfiniteListState<SentinelInfo>>().having(
          (InfiniteListState<SentinelInfo> s) => s.status,
          'status',
          InfiniteListStatus.failure,
        ),
      ],
    );
  });
}
