import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockTokenApi extends Mock implements TokenApi {}

class MockTokenList extends Mock implements TokenList {}

class MockToken extends Mock implements Token {}

class FakeTokenStandard extends Fake implements TokenStandard {
  FakeTokenStandard(this.value);

  final String value;

  @override
  String toString() => value;
}

class FakeAddress extends Fake implements Address {
  FakeAddress(this.value);

  final String value;

  @override
  String toString() => value;
}

void main() {
  group('SearchTokenBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockTokenApi tokenApi;
    late MockTokenList tokenList;
    late List<Token> tokens;

    MockToken createToken(
      String symbol, {
      String name = 'Token',
      String owner = 'z1qowner',
      String? tokenStandard,
    }) {
      final MockToken token = MockToken();
      final FakeAddress ownerAddress = FakeAddress(owner);
      final FakeTokenStandard standard = FakeTokenStandard(
        tokenStandard ?? 'zts1${symbol.toLowerCase()}',
      );
      when(() => token.name).thenReturn(name);
      when(() => token.symbol).thenReturn(symbol);
      when(() => token.owner).thenReturn(ownerAddress);
      when(() => token.tokenStandard).thenReturn(standard);
      return token;
    }

    SearchTokenBloc createBloc({
      Duration debounceDuration = Duration.zero,
    }) {
      return SearchTokenBloc(
        zenon: zenon,
        debounceDuration: debounceDuration,
      );
    }

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      tokenApi = MockTokenApi();
      tokenList = MockTokenList();
      tokens = <Token>[];

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.token).thenReturn(tokenApi);
      when(() => tokenList.list).thenAnswer((_) => tokens);
      when(
        () => tokenApi.getAll(
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => tokenList);
    });

    test('initial state is correct', () {
      expect(createBloc().state, const SearchTokenInitial());
    });

    blocTest<SearchTokenBloc, SearchTokenState>(
      'searches symbols case-insensitively and excludes native coins',
      setUp: () {
        tokens = <Token>[
          kZnnCoin,
          createToken('ZNNEX'),
          createToken('OTHER'),
        ];
      },
      build: createBloc,
      act: (SearchTokenBloc bloc) =>
          bloc.add(const SearchTokenRequested(query: 'znn')),
      verify: (_) {
        verify(
          () => tokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).called(1);
      },
      expect: () => <SearchTokenState>[
        const SearchTokenLoading(query: 'znn'),
        SearchTokenPopulated(
          query: 'znn',
          tokens: <Token>[tokens[1]],
        ),
      ],
    );

    blocTest<SearchTokenBloc, SearchTokenState>(
      'returns all matching tokens together',
      setUp: () {
        tokens = <Token>[
          createToken('ALPHA'),
          createToken('ALPINE'),
        ];
      },
      build: createBloc,
      act: (SearchTokenBloc bloc) =>
          bloc.add(const SearchTokenRequested(query: 'alp')),
      expect: () => <SearchTokenState>[
        const SearchTokenLoading(query: 'alp'),
        SearchTokenPopulated(
          query: 'alp',
          tokens: tokens,
        ),
      ],
    );

    late Token tokenOnSecondPage;

    blocTest<SearchTokenBloc, SearchTokenState>(
      'finds tokens from later RPC pages',
      setUp: () {
        tokenOnSecondPage = createToken(
          'LATER',
          name: 'Second Page Token',
        );
        final TokenList firstPage = TokenList(
          count: rpcMaxPageSize + 1,
          list: List<Token>.filled(
            rpcMaxPageSize,
            createToken('OTHER', name: 'Other Token'),
          ),
        );
        final TokenList secondPage = TokenList(
          count: rpcMaxPageSize + 1,
          list: <Token>[tokenOnSecondPage],
        );
        when(
          () => tokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final int pageIndex = invocation.namedArguments[#pageIndex]! as int;
          return pageIndex == 0 ? firstPage : secondPage;
        });
      },
      build: createBloc,
      act: (SearchTokenBloc bloc) =>
          bloc.add(const SearchTokenRequested(query: 'later')),
      verify: (_) {
        expect(
          verify(
            () => tokenApi.getAll(
              pageIndex: captureAny(named: 'pageIndex'),
              pageSize: any(named: 'pageSize'),
            ),
          ).captured,
          <int>[0, 1],
        );
      },
      expect: () => <SearchTokenState>[
        const SearchTokenLoading(query: 'later'),
        SearchTokenPopulated(
          query: 'later',
          tokens: <Token>[tokenOnSecondPage],
        ),
      ],
    );

    blocTest<SearchTokenBloc, SearchTokenState>(
      'searches tokens by name',
      setUp: () {
        tokens = <Token>[
          createToken('ONE', name: 'First Token'),
          createToken('TWO', name: 'Second Token'),
        ];
      },
      build: createBloc,
      act: (SearchTokenBloc bloc) =>
          bloc.add(const SearchTokenRequested(query: 'SECOND')),
      expect: () => <SearchTokenState>[
        const SearchTokenLoading(query: 'SECOND'),
        SearchTokenPopulated(
          query: 'SECOND',
          tokens: <Token>[tokens[1]],
        ),
      ],
    );

    blocTest<SearchTokenBloc, SearchTokenState>(
      'searches tokens by owner',
      setUp: () {
        tokens = <Token>[
          createToken('ONE', owner: 'z1qfirstowner'),
          createToken('TWO', owner: 'z1qsecondowner'),
        ];
      },
      build: createBloc,
      act: (SearchTokenBloc bloc) =>
          bloc.add(const SearchTokenRequested(query: 'SECONDOWNER')),
      expect: () => <SearchTokenState>[
        const SearchTokenLoading(query: 'SECONDOWNER'),
        SearchTokenPopulated(
          query: 'SECONDOWNER',
          tokens: <Token>[tokens[1]],
        ),
      ],
    );

    blocTest<SearchTokenBloc, SearchTokenState>(
      'searches tokens by token standard',
      setUp: () {
        tokens = <Token>[
          createToken('ONE', tokenStandard: 'zts1firststandard'),
          createToken('TWO', tokenStandard: 'zts1secondstandard'),
        ];
      },
      build: createBloc,
      act: (SearchTokenBloc bloc) =>
          bloc.add(const SearchTokenRequested(query: 'SECONDSTANDARD')),
      expect: () => <SearchTokenState>[
        const SearchTokenLoading(query: 'SECONDSTANDARD'),
        SearchTokenPopulated(
          query: 'SECONDSTANDARD',
          tokens: <Token>[tokens[1]],
        ),
      ],
    );

    blocTest<SearchTokenBloc, SearchTokenState>(
      'debounces input and searches only the latest query',
      setUp: () {
        tokens = <Token>[
          createToken('ALPHA'),
          createToken('BETA'),
        ];
      },
      build: () => createBloc(
        debounceDuration: const Duration(milliseconds: 50),
      ),
      act: (SearchTokenBloc bloc) {
        bloc
          ..add(const SearchTokenRequested(query: 'alp'))
          ..add(const SearchTokenRequested(query: 'beta'));
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(
          () => tokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).called(1);
      },
      expect: () => <SearchTokenState>[
        const SearchTokenLoading(query: 'beta'),
        SearchTokenPopulated(
          query: 'beta',
          tokens: <Token>[tokens[1]],
        ),
      ],
    );

    blocTest<SearchTokenBloc, SearchTokenState>(
      'reuses cached tokens across queries',
      setUp: () {
        tokens = <Token>[
          createToken('ALPHA'),
          createToken('BETA'),
        ];
      },
      build: createBloc,
      act: (SearchTokenBloc bloc) async {
        bloc.add(const SearchTokenRequested(query: 'alpha'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SearchTokenRequested(query: 'beta'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (_) {
        verify(
          () => tokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).called(1);
      },
      expect: () => <SearchTokenState>[
        const SearchTokenLoading(query: 'alpha'),
        SearchTokenPopulated(
          query: 'alpha',
          tokens: <Token>[tokens[0]],
        ),
        const SearchTokenLoading(query: 'beta'),
        SearchTokenPopulated(
          query: 'beta',
          tokens: <Token>[tokens[1]],
        ),
      ],
    );

    blocTest<SearchTokenBloc, SearchTokenState>(
      'emits failure when fetching all tokens fails',
      setUp: () {
        when(
          () => tokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenThrow(Exception('boom'));
      },
      build: createBloc,
      act: (SearchTokenBloc bloc) =>
          bloc.add(const SearchTokenRequested(query: 'token')),
      expect: () => <Matcher>[
        equals(const SearchTokenLoading(query: 'token')),
        isA<SearchTokenFailure>().having(
          (SearchTokenFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
