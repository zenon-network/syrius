import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/tokens/bloc/tokens_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockTokenApi extends Mock implements TokenApi {}

Token _buildToken({
  required String name,
  required String symbol,
  required int seedByte,
}) => Token(
  name,
  symbol,
  'example.com',
  BigInt.from(100),
  0,
  emptyAddress,
  TokenStandard.fromBytes(List<int>.filled(TokenStandard.coreSize, seedByte)),
  BigInt.from(1000),
  false,
  false,
  true,
);

void main() {
  initHydratedStorage();

  group('TokensBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockTokenApi tokenApi;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      tokenApi = MockTokenApi();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.token).thenReturn(tokenApi);
    });

    blocTest<TokensBloc, InfiniteListState<Token>>(
      'paginates tokens in RPC order across pages',
      setUp: () {
        final List<Token> page0 = <Token>[
          _buildToken(name: 'Alpha', symbol: 'ALP', seedByte: 1),
          _buildToken(name: 'Beta', symbol: 'BET', seedByte: 2),
        ];
        final List<Token> page1 = <Token>[
          _buildToken(name: 'Gamma', symbol: 'GAM', seedByte: 3),
        ];

        when(
          () => tokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final int pageIndex = invocation.namedArguments[#pageIndex]! as int;
          return TokenList(count: 3, list: pageIndex == 0 ? page0 : page1);
        });
      },
      build: () => TokensBloc(zenon: zenon, pageSize: 2),
      act: (TokensBloc bloc) async {
        bloc.add(const InfiniteListRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const InfiniteListMoreRequested());
      },
      verify: (_) {
        expect(
          verify(
            () => tokenApi.getAll(
              pageIndex: captureAny(named: 'pageIndex'),
              pageSize: 2,
            ),
          ).captured,
          <int>[0, 1],
        );
      },
      expect: () => <Matcher>[
        isA<InfiniteListState<Token>>()
            .having(
              (InfiniteListState<Token> s) => s.status,
              'status',
              InfiniteListStatus.success,
            )
            .having(
              (InfiniteListState<Token> s) => s.hasReachedMax,
              'hasReachedMax',
              isFalse,
            )
            .having(
              (InfiniteListState<Token> s) =>
                  s.data!.map((Token t) => t.symbol).toList(),
              'symbols',
              <String>['ALP', 'BET'],
            ),
        isA<InfiniteListState<Token>>()
            .having(
              (InfiniteListState<Token> s) => s.status,
              'status',
              InfiniteListStatus.success,
            )
            .having(
              (InfiniteListState<Token> s) => s.hasReachedMax,
              'hasReachedMax',
              isTrue,
            )
            .having(
              (InfiniteListState<Token> s) =>
                  s.data!.map((Token t) => t.symbol).toList(),
              'symbols',
              <String>['ALP', 'BET', 'GAM'],
            ),
      ],
    );
  });
}
