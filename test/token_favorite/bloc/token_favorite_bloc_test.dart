import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  group('TokenFavoriteBloc', () {
    late MockBox favoriteTokensBox;

    setUp(() {
      favoriteTokensBox = MockBox();
      when(() => favoriteTokensBox.values).thenReturn(<dynamic>[]);
    });

    TokenFavoriteBloc buildBloc() => TokenFavoriteBloc(
      favoriteTokensBox: favoriteTokensBox,
      tokenStandard: znnZts,
    );

    test('starts with remove success when token is not a favorite', () {
      expect(
        buildBloc().state,
        const TokenFavoriteRemoveSuccess(),
      );
    });

    test('starts with add success when token is a favorite', () {
      when(
        () => favoriteTokensBox.values,
      ).thenReturn(<dynamic>[znnZts.toString()]);

      expect(
        buildBloc().state,
        const TokenFavoriteAddSuccess(),
      );
    });

    blocTest<TokenFavoriteBloc, TokenFavoriteState>(
      'adds a token to favorites',
      setUp: () {
        when(
          () => favoriteTokensBox.add(znnZts.toString()),
        ).thenAnswer((_) async => 0);
      },
      build: buildBloc,
      act: (TokenFavoriteBloc bloc) => bloc.add(const TokenFavoriteAdded()),
      expect: () => <TokenFavoriteState>[
        const TokenFavoriteLoading(),
        const TokenFavoriteAddSuccess(),
      ],
      verify: (_) {
        verify(
          () => favoriteTokensBox.add(znnZts.toString()),
        ).called(1);
      },
    );

    blocTest<TokenFavoriteBloc, TokenFavoriteState>(
      'removes a token from favorites',
      setUp: () {
        when(
          () => favoriteTokensBox.values,
        ).thenReturn(<dynamic>[znnZts.toString()]);
        when(() => favoriteTokensBox.deleteAt(0)).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (TokenFavoriteBloc bloc) => bloc.add(const TokenFavoriteRemoved()),
      expect: () => <TokenFavoriteState>[
        const TokenFavoriteLoading(),
        const TokenFavoriteRemoveSuccess(),
      ],
      verify: (_) {
        verify(() => favoriteTokensBox.deleteAt(0)).called(1);
      },
    );

    blocTest<TokenFavoriteBloc, TokenFavoriteState>(
      'emits an add failure when storage throws',
      setUp: () {
        when(
          () => favoriteTokensBox.add(znnZts.toString()),
        ).thenThrow(Exception('add failed'));
      },
      build: buildBloc,
      act: (TokenFavoriteBloc bloc) => bloc.add(const TokenFavoriteAdded()),
      expect: () => <Matcher>[
        isA<TokenFavoriteLoading>(),
        isA<TokenFavoriteAddFailure>().having(
          (TokenFavoriteAddFailure state) => state.error,
          'error',
          isA<Exception>(),
        ),
      ],
    );

    blocTest<TokenFavoriteBloc, TokenFavoriteState>(
      'emits a remove failure when storage throws',
      setUp: () {
        when(
          () => favoriteTokensBox.values,
        ).thenReturn(<dynamic>[znnZts.toString()]);
        when(
          () => favoriteTokensBox.deleteAt(0),
        ).thenThrow(Exception('remove failed'));
      },
      build: buildBloc,
      act: (TokenFavoriteBloc bloc) => bloc.add(const TokenFavoriteRemoved()),
      expect: () => <Matcher>[
        isA<TokenFavoriteLoading>(),
        isA<TokenFavoriteRemoveFailure>().having(
          (TokenFavoriteRemoveFailure state) => state.error,
          'error',
          isA<Exception>(),
        ),
      ],
    );
  });
}
