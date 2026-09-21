import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockTokenApi extends Mock implements TokenApi {}

class MockTokenList extends Mock implements TokenList {}

class MockToken extends Mock implements Token {}

void main() {
  initHydratedStorage();

  group('AllTokensBloc', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockTokenApi mockTokenApi;
    late MockTokenList mockTokenList;
    late MockToken token;
    late AllTokensBloc bloc;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockTokenApi = MockTokenApi();
      mockTokenList = MockTokenList();
      token = MockToken();

      when(() => token.toJson()).thenReturn(<String, dynamic>{
        'name': 'token',
        'symbol': 'TKN',
        'domain': 'zenon.network',
        'totalSupply': '1',
        'decimals': 8,
        'owner': emptyAddress.toString(),
        'tokenStandard': znnZts.toString(),
        'maxSupply': '1',
        'isBurnable': false,
        'isMintable': false,
        'isUtility': true,
      });
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.token).thenReturn(mockTokenApi);
      when(() => mockTokenList.count).thenReturn(1);
      when(() => mockTokenList.list).thenReturn(<Token>[token]);
      when(
        () => mockTokenApi.getAll(
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => mockTokenList);

      bloc = AllTokensBloc(zenon: mockZenon);
    });

    test('initial state is initial', () {
      expect(bloc.state, const AllTokensInitial());
    });

    test('state variants round trip through JSON', () {
      final AllTokensState initial = AllTokensState.fromJson(
        const AllTokensInitial().toJson(),
      );
      final AllTokensState failure = AllTokensState.fromJson(
        AllTokensFailure(exception: FailureException()).toJson(),
      );
      final AllTokensState populated = AllTokensState.fromJson(
        AllTokensPopulated(data: <Token>[token]).toJson(),
      );

      expect(initial, const AllTokensInitial());
      expect(failure, isA<AllTokensFailure>());
      expect(populated, isA<AllTokensPopulated>());
      expect((populated as AllTokensPopulated).data, hasLength(1));
    });

    blocTest<AllTokensBloc, AllTokensState>(
      'emits success when fetch returns all_tokens',
      build: () => bloc,
      act: (AllTokensBloc bloc) => bloc.add(const AllTokensRequested()),
      verify: (_) {
        verify(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).called(1);
      },
      expect: () => <AllTokensState>[
        AllTokensPopulated(
          data: <Token>[token],
        ),
      ],
    );

    blocTest<AllTokensBloc, AllTokensState>(
      'fetches every page when the token count exceeds the RPC limit',
      setUp: () {
        final TokenList firstPage = TokenList(
          count: rpcMaxPageSize + 1,
          list: List<Token>.filled(rpcMaxPageSize, token),
        );
        final TokenList secondPage = TokenList(
          count: rpcMaxPageSize + 1,
          list: <Token>[token],
        );
        when(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final int pageIndex = invocation.namedArguments[#pageIndex]! as int;
          return pageIndex == 0 ? firstPage : secondPage;
        });
      },
      build: () => bloc,
      act: (AllTokensBloc bloc) => bloc.add(const AllTokensRequested()),
      verify: (_) {
        expect(
          verify(
            () => mockTokenApi.getAll(
              pageIndex: captureAny(named: 'pageIndex'),
              pageSize: any(named: 'pageSize'),
            ),
          ).captured,
          <int>[0, 1],
        );
      },
      expect: () => <Matcher>[
        isA<AllTokensPopulated>().having(
          (AllTokensPopulated state) => state.data.length,
          'token count',
          rpcMaxPageSize + 1,
        ),
      ],
    );

    blocTest<AllTokensBloc, AllTokensState>(
      'emits failure when a later page throws',
      setUp: () {
        final TokenList firstPage = TokenList(
          count: rpcMaxPageSize + 1,
          list: List<Token>.filled(rpcMaxPageSize, token),
        );
        when(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final int pageIndex = invocation.namedArguments[#pageIndex]! as int;
          if (pageIndex == 1) throw Exception('boom');
          return firstPage;
        });
      },
      build: () => bloc,
      act: (AllTokensBloc bloc) => bloc.add(const AllTokensRequested()),
      expect: () => <Matcher>[
        isA<AllTokensFailure>().having(
          (AllTokensFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<AllTokensBloc, AllTokensState>(
      'emits failure when fetch throws',
      setUp: () {
        when(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (AllTokensBloc bloc) => bloc.add(const AllTokensRequested()),
      expect: () => <Matcher>[
        isA<AllTokensFailure>().having(
          (AllTokensFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
