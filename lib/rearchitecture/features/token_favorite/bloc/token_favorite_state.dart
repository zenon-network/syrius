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

/// Success state emitted after the token is added to favorites.
final class TokenFavoriteAddSuccess extends TokenFavoriteState {
  /// Creates a [TokenFavoriteAddSuccess] state.
  const TokenFavoriteAddSuccess();
}

/// Success state emitted after the token is removed from favorites.
final class TokenFavoriteRemoveSuccess extends TokenFavoriteState {
  /// Creates a [TokenFavoriteRemoveSuccess] state.
  const TokenFavoriteRemoveSuccess();
}

/// Failure state emitted when adding the token fails.
final class TokenFavoriteAddFailure extends TokenFavoriteState {
  /// Creates a [TokenFavoriteAddFailure] state.
  const TokenFavoriteAddFailure({required this._error});

  final Object _error;

  /// Error that prevented the token from being added.
  Object get error => _error;

  @override
  List<Object?> get props => <Object?>[_error];
}

/// Failure state emitted when removing the token fails.
final class TokenFavoriteRemoveFailure extends TokenFavoriteState {
  /// Creates a [TokenFavoriteRemoveFailure] state.
  const TokenFavoriteRemoveFailure({required this._error});

  final Object _error;

  /// Error that prevented the token from being removed.
  Object get error => _error;

  @override
  List<Object?> get props => <Object?>[_error];
}
