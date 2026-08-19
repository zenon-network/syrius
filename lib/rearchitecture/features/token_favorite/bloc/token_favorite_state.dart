part of 'token_favorite_bloc.dart';

/// Base class for token-favorite states.
sealed class TokenFavoriteState extends Equatable {
  /// Creates a [TokenFavoriteState].
  const TokenFavoriteState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Loading state while the favorite value is being changed.
final class TokenFavoriteLoading extends TokenFavoriteState {
  /// Creates a [TokenFavoriteLoading] state.
  const TokenFavoriteLoading();
}

/// State indicating that the token is a favorite.
final class TokenFavoriteFavorited extends TokenFavoriteState {
  /// Creates a [TokenFavoriteFavorited] state.
  const TokenFavoriteFavorited();
}

/// State indicating that the token is not a favorite.
final class TokenFavoriteNotFavorited extends TokenFavoriteState {
  /// Creates a [TokenFavoriteNotFavorited] state.
  const TokenFavoriteNotFavorited();
}

/// Failure state emitted when changing the favorite value fails.
final class TokenFavoriteFailure extends TokenFavoriteState {
  /// Creates a [TokenFavoriteFailure] state.
  const TokenFavoriteFailure({required this.exception});

  /// Exception that describes the failed favorite-token operation.
  final FavoriteTokensException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
