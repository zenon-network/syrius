part of 'token_favorite_bloc.dart';

/// Base class for token-favorite events.
sealed class TokenFavoriteEvent extends Equatable {
  /// Creates a [TokenFavoriteEvent].
  const TokenFavoriteEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests adding the token to the wallet favorites.
final class TokenFavoriteAdded extends TokenFavoriteEvent {
  /// Creates a [TokenFavoriteAdded] event.
  const TokenFavoriteAdded();
}

/// Requests removing the token from the wallet favorites.
final class TokenFavoriteRemoved extends TokenFavoriteEvent {
  /// Creates a [TokenFavoriteRemoved] event.
  const TokenFavoriteRemoved();
}
