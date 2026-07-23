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
      int pageSize = 10,
      Duration debounceDuration = Duration.zero,
    }) {
      return SearchTokenBloc(
        zenon: zenon,
        pageSize: pageSize,
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
      when(() => tokenApi.getAll()).thenAnswer((_) async => tokenList);
    });

    test('initial state is correct', () {
      expect(createBloc().state, const SearchTokenState.initial());
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
        verify(() => tokenApi.getAll()).called(1);
      },
      expect: () => <SearchTokenState>[
        const SearchTokenState.loading(query: 'znn'),
        SearchTokenState.success(
          query: 'znn',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<SearchTokenBloc, SearchTokenState>(
      'paginates matching tokens locally',
      setUp: () {
        tokens = <Token>[
          createToken('ALPHA'),
          createToken('ALPINE'),
        ];
      },
      build: () => createBloc(pageSize: 1),
      act: (SearchTokenBloc bloc) async {
        bloc.add(const SearchTokenRequested(query: 'alp'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const SearchTokenMoreRequested());
      },
      expect: () => <SearchTokenState>[
        const SearchTokenState.loading(query: 'alp'),
        SearchTokenState.success(
          query: 'alp',
          tokens: <Token>[tokens[0]],
          hasReachedMax: false,
        ),
        SearchTokenState.success(
          query: 'alp',
          tokens: tokens,
          hasReachedMax: true,
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
        const SearchTokenState.loading(query: 'SECOND'),
        SearchTokenState.success(
          query: 'SECOND',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
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
        const SearchTokenState.loading(query: 'SECONDOWNER'),
        SearchTokenState.success(
          query: 'SECONDOWNER',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
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
        const SearchTokenState.loading(query: 'SECONDSTANDARD'),
        SearchTokenState.success(
          query: 'SECONDSTANDARD',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
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
        verify(() => tokenApi.getAll()).called(1);
      },
      expect: () => <SearchTokenState>[
        const SearchTokenState.loading(query: 'beta'),
        SearchTokenState.success(
          query: 'beta',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
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
        verify(() => tokenApi.getAll()).called(1);
      },
      expect: () => <SearchTokenState>[
        const SearchTokenState.loading(query: 'alpha'),
        SearchTokenState.success(
          query: 'alpha',
          tokens: <Token>[tokens[0]],
          hasReachedMax: true,
        ),
        const SearchTokenState.loading(query: 'beta'),
        SearchTokenState.success(
          query: 'beta',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<SearchTokenBloc, SearchTokenState>(
      'emits failure when fetching all tokens fails',
      setUp: () {
        when(() => tokenApi.getAll()).thenThrow(Exception('boom'));
      },
      build: createBloc,
      act: (SearchTokenBloc bloc) =>
          bloc.add(const SearchTokenRequested(query: 'token')),
      expect: () => <Matcher>[
        equals(const SearchTokenState.loading(query: 'token')),
        isA<SearchTokenState>()
            .having(
              (SearchTokenState state) => state.status,
              'status',
              SearchTokenStatus.failure,
            )
            .having(
              (SearchTokenState state) => state.error,
              'error',
              isA<FailureException>(),
            ),
      ],
    );
  });
}
