import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockFavoriteTokensRepository extends Mock
    implements FavoriteTokensRepository {}

void main() {
  group('TokenFavoriteBloc', () {
    late MockFavoriteTokensRepository repository;
    late Exception addCause;
    late Exception removeCause;

    setUp(() {
      repository = MockFavoriteTokensRepository();
      addCause = Exception('add failed');
      removeCause = Exception('remove failed');
      when(() => repository.contains(znnZts)).thenReturn(false);
    });

    TokenFavoriteBloc buildBloc() => TokenFavoriteBloc(
      repository: repository,
      tokenStandard: znnZts,
    );

    test('starts not favorited when token is not a favorite', () {
      expect(
        buildBloc().state,
        const TokenFavoriteNotFavorited(),
      );
    });

    test('starts favorited when token is a favorite', () {
      when(() => repository.contains(znnZts)).thenReturn(true);

      expect(
        buildBloc().state,
        const TokenFavoriteFavorited(),
      );
    });

    blocTest<TokenFavoriteBloc, TokenFavoriteState>(
      'adds a token to favorites',
      setUp: () {
        when(() => repository.add(znnZts)).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (TokenFavoriteBloc bloc) => bloc.add(const TokenFavoriteAdded()),
      expect: () => <TokenFavoriteState>[
        const TokenFavoriteLoading(),
        const TokenFavoriteFavorited(),
      ],
      verify: (_) {
        verify(() => repository.add(znnZts)).called(1);
      },
    );

    blocTest<TokenFavoriteBloc, TokenFavoriteState>(
      'removes a token from favorites',
      setUp: () {
        when(() => repository.contains(znnZts)).thenReturn(true);
        when(() => repository.remove(znnZts)).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (TokenFavoriteBloc bloc) => bloc.add(const TokenFavoriteRemoved()),
      expect: () => <TokenFavoriteState>[
        const TokenFavoriteLoading(),
        const TokenFavoriteNotFavorited(),
      ],
      verify: (_) {
        verify(() => repository.remove(znnZts)).called(1);
      },
    );

    blocTest<TokenFavoriteBloc, TokenFavoriteState>(
      'emits an add failure when storage throws',
      setUp: () {
        when(() => repository.add(znnZts)).thenThrow(
          AddingToFavoriteTokensException(cause: addCause),
        );
      },
      build: buildBloc,
      act: (TokenFavoriteBloc bloc) => bloc.add(const TokenFavoriteAdded()),
      expect: () => <Matcher>[
        isA<TokenFavoriteLoading>(),
        isA<TokenFavoriteFailure>().having(
          (TokenFavoriteFailure state) => state.exception,
          'exception',
          isA<AddingToFavoriteTokensException>().having(
            (AddingToFavoriteTokensException exception) => exception.cause,
            'cause',
            same(addCause),
          ),
        ),
      ],
    );

    blocTest<TokenFavoriteBloc, TokenFavoriteState>(
      'wraps an unexpected add error',
      setUp: () {
        when(() => repository.add(znnZts)).thenThrow(addCause);
      },
      build: buildBloc,
      act: (TokenFavoriteBloc bloc) => bloc.add(const TokenFavoriteAdded()),
      expect: () => <Matcher>[
        isA<TokenFavoriteLoading>(),
        isA<TokenFavoriteFailure>().having(
          (TokenFavoriteFailure state) => state.exception,
          'exception',
          isA<AddingToFavoriteTokensException>().having(
            (AddingToFavoriteTokensException exception) => exception.cause,
            'cause',
            same(addCause),
          ),
        ),
      ],
    );

    blocTest<TokenFavoriteBloc, TokenFavoriteState>(
      'emits a remove failure when storage throws',
      setUp: () {
        when(() => repository.contains(znnZts)).thenReturn(true);
        when(() => repository.remove(znnZts)).thenThrow(
          RemovingFromFavoriteTokensException(cause: removeCause),
        );
      },
      build: buildBloc,
      act: (TokenFavoriteBloc bloc) => bloc.add(const TokenFavoriteRemoved()),
      expect: () => <Matcher>[
        isA<TokenFavoriteLoading>(),
        isA<TokenFavoriteFailure>().having(
          (TokenFavoriteFailure state) => state.exception,
          'exception',
          isA<RemovingFromFavoriteTokensException>().having(
            (RemovingFromFavoriteTokensException exception) => exception.cause,
            'cause',
            same(removeCause),
          ),
        ),
      ],
    );

    blocTest<TokenFavoriteBloc, TokenFavoriteState>(
      'wraps an unexpected remove error',
      setUp: () {
        when(() => repository.contains(znnZts)).thenReturn(true);
        when(() => repository.remove(znnZts)).thenThrow(removeCause);
      },
      build: buildBloc,
      act: (TokenFavoriteBloc bloc) => bloc.add(const TokenFavoriteRemoved()),
      expect: () => <Matcher>[
        isA<TokenFavoriteLoading>(),
        isA<TokenFavoriteFailure>().having(
          (TokenFavoriteFailure state) => state.exception,
          'exception',
          isA<RemovingFromFavoriteTokensException>().having(
            (RemovingFromFavoriteTokensException exception) => exception.cause,
            'cause',
            same(removeCause),
          ),
        ),
      ],
    );
  });
}
