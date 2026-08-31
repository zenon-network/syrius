import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/token_favorite/exceptions/favorite_tokens_exception.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/token_favorite/repository/favorite_tokens_repository.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'token_favorite_event.dart';

part 'token_favorite_state.dart';

/// A bloc that adds or removes a token from the wallet favorites.
class TokenFavoriteBloc extends Bloc<TokenFavoriteEvent, TokenFavoriteState> {
  /// Creates a [TokenFavoriteBloc] for [tokenStandard].
  factory TokenFavoriteBloc({
    required TokenStandard tokenStandard,
    FavoriteTokensRepository? repository,
  }) {
    final FavoriteTokensRepository favoriteTokensRepository =
        repository ?? HiveFavoriteTokensRepository();
    return TokenFavoriteBloc._(
      repository: favoriteTokensRepository,
      tokenStandard: tokenStandard,
    );
  }

  TokenFavoriteBloc._({
    required FavoriteTokensRepository repository,
    required TokenStandard tokenStandard,
  }) : _repository = repository,
       _tokenStandard = tokenStandard,
       super(
         repository.contains(tokenStandard)
             ? const TokenFavoriteFavorited()
             : const TokenFavoriteNotFavorited(),
       ) {
    on<TokenFavoriteAdded>(_onTokenFavoriteAdded);
    on<TokenFavoriteRemoved>(_onTokenFavoriteRemoved);
  }

  final FavoriteTokensRepository _repository;
  final TokenStandard _tokenStandard;

  FutureOr<void> _onTokenFavoriteAdded(
    TokenFavoriteAdded event,
    Emitter<TokenFavoriteState> emit,
  ) async {
    if (state is TokenFavoriteLoading) {
      return;
    }

    emit(const TokenFavoriteLoading());
    try {
      await _repository.add(_tokenStandard);
      emit(const TokenFavoriteFavorited());
    } on Object catch (error, stackTrace) {
      final AddingToFavoriteTokensException exception =
          error is AddingToFavoriteTokensException
          ? error
          : AddingToFavoriteTokensException(cause: error);
      addError(exception, stackTrace);
      emit(TokenFavoriteFailure(exception: exception));
    }
  }

  FutureOr<void> _onTokenFavoriteRemoved(
    TokenFavoriteRemoved event,
    Emitter<TokenFavoriteState> emit,
  ) async {
    if (state is TokenFavoriteLoading) {
      return;
    }

    emit(const TokenFavoriteLoading());
    try {
      await _repository.remove(_tokenStandard);
      emit(const TokenFavoriteNotFavorited());
    } on Object catch (error, stackTrace) {
      final RemovingFromFavoriteTokensException exception =
          error is RemovingFromFavoriteTokensException
          ? error
          : RemovingFromFavoriteTokensException(cause: error);
      addError(exception, stackTrace);
      emit(TokenFavoriteFailure(exception: exception));
    }
  }
}
