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
  group('TokenSearchBloc', () {
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

    TokenSearchBloc createBloc({
      int pageSize = 10,
      Duration debounceDuration = Duration.zero,
    }) {
      return TokenSearchBloc(
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
      expect(createBloc().state, const TokenSearchState.initial());
    });

    blocTest<TokenSearchBloc, TokenSearchState>(
      'searches symbols case-insensitively and excludes native coins',
      setUp: () {
        tokens = <Token>[
          kZnnCoin,
          createToken('ZNNEX'),
          createToken('OTHER'),
        ];
      },
      build: createBloc,
      act: (TokenSearchBloc bloc) =>
          bloc.add(const TokenSearchRequested(query: 'znn')),
      verify: (_) {
        verify(() => tokenApi.getAll()).called(1);
      },
      expect: () => <TokenSearchState>[
        const TokenSearchState.loading(query: 'znn'),
        TokenSearchState.success(
          query: 'znn',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<TokenSearchBloc, TokenSearchState>(
      'paginates matching tokens locally',
      setUp: () {
        tokens = <Token>[
          createToken('ALPHA'),
          createToken('ALPINE'),
        ];
      },
      build: () => createBloc(pageSize: 1),
      act: (TokenSearchBloc bloc) async {
        bloc.add(const TokenSearchRequested(query: 'alp'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const TokenSearchMoreRequested());
      },
      expect: () => <TokenSearchState>[
        const TokenSearchState.loading(query: 'alp'),
        TokenSearchState.success(
          query: 'alp',
          tokens: <Token>[tokens[0]],
          hasReachedMax: false,
        ),
        TokenSearchState.success(
          query: 'alp',
          tokens: tokens,
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<TokenSearchBloc, TokenSearchState>(
      'searches tokens by name',
      setUp: () {
        tokens = <Token>[
          createToken('ONE', name: 'First Token'),
          createToken('TWO', name: 'Second Token'),
        ];
      },
      build: createBloc,
      act: (TokenSearchBloc bloc) =>
          bloc.add(const TokenSearchRequested(query: 'SECOND')),
      expect: () => <TokenSearchState>[
        const TokenSearchState.loading(query: 'SECOND'),
        TokenSearchState.success(
          query: 'SECOND',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<TokenSearchBloc, TokenSearchState>(
      'searches tokens by owner',
      setUp: () {
        tokens = <Token>[
          createToken('ONE', owner: 'z1qfirstowner'),
          createToken('TWO', owner: 'z1qsecondowner'),
        ];
      },
      build: createBloc,
      act: (TokenSearchBloc bloc) =>
          bloc.add(const TokenSearchRequested(query: 'SECONDOWNER')),
      expect: () => <TokenSearchState>[
        const TokenSearchState.loading(query: 'SECONDOWNER'),
        TokenSearchState.success(
          query: 'SECONDOWNER',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<TokenSearchBloc, TokenSearchState>(
      'searches tokens by token standard',
      setUp: () {
        tokens = <Token>[
          createToken('ONE', tokenStandard: 'zts1firststandard'),
          createToken('TWO', tokenStandard: 'zts1secondstandard'),
        ];
      },
      build: createBloc,
      act: (TokenSearchBloc bloc) =>
          bloc.add(const TokenSearchRequested(query: 'SECONDSTANDARD')),
      expect: () => <TokenSearchState>[
        const TokenSearchState.loading(query: 'SECONDSTANDARD'),
        TokenSearchState.success(
          query: 'SECONDSTANDARD',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<TokenSearchBloc, TokenSearchState>(
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
      act: (TokenSearchBloc bloc) {
        bloc
          ..add(const TokenSearchRequested(query: 'alp'))
          ..add(const TokenSearchRequested(query: 'beta'));
      },
      wait: const Duration(milliseconds: 100),
      verify: (_) {
        verify(() => tokenApi.getAll()).called(1);
      },
      expect: () => <TokenSearchState>[
        const TokenSearchState.loading(query: 'beta'),
        TokenSearchState.success(
          query: 'beta',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<TokenSearchBloc, TokenSearchState>(
      'reuses cached tokens across queries',
      setUp: () {
        tokens = <Token>[
          createToken('ALPHA'),
          createToken('BETA'),
        ];
      },
      build: createBloc,
      act: (TokenSearchBloc bloc) async {
        bloc.add(const TokenSearchRequested(query: 'alpha'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const TokenSearchRequested(query: 'beta'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      },
      verify: (_) {
        verify(() => tokenApi.getAll()).called(1);
      },
      expect: () => <TokenSearchState>[
        const TokenSearchState.loading(query: 'alpha'),
        TokenSearchState.success(
          query: 'alpha',
          tokens: <Token>[tokens[0]],
          hasReachedMax: true,
        ),
        const TokenSearchState.loading(query: 'beta'),
        TokenSearchState.success(
          query: 'beta',
          tokens: <Token>[tokens[1]],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<TokenSearchBloc, TokenSearchState>(
      'emits failure when fetching all tokens fails',
      setUp: () {
        when(() => tokenApi.getAll()).thenThrow(Exception('boom'));
      },
      build: createBloc,
      act: (TokenSearchBloc bloc) =>
          bloc.add(const TokenSearchRequested(query: 'token')),
      expect: () => <Matcher>[
        equals(const TokenSearchState.loading(query: 'token')),
        isA<TokenSearchState>()
            .having(
              (TokenSearchState state) => state.status,
              'status',
              TokenSearchStatus.failure,
            )
            .having(
              (TokenSearchState state) => state.error,
              'error',
              isA<FailureException>(),
            ),
      ],
    );
  });
}
