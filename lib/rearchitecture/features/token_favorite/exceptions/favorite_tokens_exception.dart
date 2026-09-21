import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

/// Base exception for failures while changing favorite tokens.
sealed class FavoriteTokensException extends SyriusException {
  /// Creates a [FavoriteTokensException] that wraps [cause].
  FavoriteTokensException({required this.cause}) : super(cause.toString());

  /// The error that caused the favorite-token operation to fail.
  final Object cause;
}

/// Exception thrown when adding a token to favorites fails.
final class AddingToFavoriteTokensException extends FavoriteTokensException {
  /// Creates an [AddingToFavoriteTokensException] that wraps [cause].
  AddingToFavoriteTokensException({required super.cause});
}

/// Exception thrown when removing a token from favorites fails.
final class RemovingFromFavoriteTokensException
    extends FavoriteTokensException {
  /// Creates a [RemovingFromFavoriteTokensException] that wraps [cause].
  RemovingFromFavoriteTokensException({required super.cause});
}
