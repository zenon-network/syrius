import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'token_favorite_event.dart';

part 'token_favorite_state.dart';

/// A bloc that adds or removes a token from the wallet favorites.
class TokenFavoriteBloc extends Bloc<TokenFavoriteEvent, TokenFavoriteState> {
  /// Creates a [TokenFavoriteBloc] for [tokenStandard].
  factory TokenFavoriteBloc({
    required TokenStandard tokenStandard,
    Box<dynamic>? favoriteTokensBox,
  }) {
    final Box<dynamic> box =
        favoriteTokensBox ?? Hive.box<dynamic>(kFavoriteTokensBox);
    return TokenFavoriteBloc._(
      favoriteTokensBox: box,
      tokenStandard: tokenStandard.toString(),
    );
  }

  TokenFavoriteBloc._({
    required Box<dynamic> favoriteTokensBox,
    required String tokenStandard,
  }) : _favoriteTokensBox = favoriteTokensBox,
       _tokenStandard = tokenStandard,
       super(
         favoriteTokensBox.values.contains(tokenStandard)
             ? const TokenFavoriteAddSuccess()
             : const TokenFavoriteRemoveSuccess(),
       ) {
    on<TokenFavoriteAdded>(_onTokenFavoriteAdded);
    on<TokenFavoriteRemoved>(_onTokenFavoriteRemoved);
  }

  final Box<dynamic> _favoriteTokensBox;
  final String _tokenStandard;

  FutureOr<void> _onTokenFavoriteAdded(
    TokenFavoriteAdded event,
    Emitter<TokenFavoriteState> emit,
  ) async {
    if (state is TokenFavoriteLoading) {
      return;
    }
    if (_favoriteTokensBox.values.contains(_tokenStandard)) {
      emit(const TokenFavoriteAddSuccess());
      return;
    }

    emit(const TokenFavoriteLoading());
    try {
      await _favoriteTokensBox.add(_tokenStandard);
      emit(const TokenFavoriteAddSuccess());
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(TokenFavoriteAddFailure(error: error));
    }
  }

  FutureOr<void> _onTokenFavoriteRemoved(
    TokenFavoriteRemoved event,
    Emitter<TokenFavoriteState> emit,
  ) async {
    if (state is TokenFavoriteLoading) {
      return;
    }

    try {
      final int index = _favoriteTokensBox.values.toList().indexOf(
        _tokenStandard,
      );
      if (index == -1) {
        emit(const TokenFavoriteRemoveSuccess());
        return;
      }

      emit(const TokenFavoriteLoading());
      await _favoriteTokensBox.deleteAt(index);
      emit(const TokenFavoriteRemoveSuccess());
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(TokenFavoriteRemoveFailure(error: error));
    }
  }
}
