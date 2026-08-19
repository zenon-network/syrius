import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/token_favorite/exceptions/favorite_tokens_exception.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Stores the token standards marked as favorites by the wallet.
abstract interface class FavoriteTokensRepository {
  /// Whether [tokenStandard] is currently a favorite.
  bool contains(TokenStandard tokenStandard);

  /// Adds [tokenStandard] to favorites if it is not already present.
  Future<void> add(TokenStandard tokenStandard);

  /// Removes [tokenStandard] from favorites if it is present.
  Future<void> remove(TokenStandard tokenStandard);
}

/// A Hive-backed [FavoriteTokensRepository].
final class HiveFavoriteTokensRepository implements FavoriteTokensRepository {
  /// Creates a repository using the wallet's favorite-token box.
  HiveFavoriteTokensRepository({Box<dynamic>? favoriteTokensBox})
    : _favoriteTokensBox =
          favoriteTokensBox ?? Hive.box<dynamic>(kFavoriteTokensBox);

  final Box<dynamic> _favoriteTokensBox;

  @override
  bool contains(TokenStandard tokenStandard) =>
      _favoriteTokensBox.values.contains(tokenStandard.toString());

  @override
  Future<void> add(TokenStandard tokenStandard) async {
    try {
      if (contains(tokenStandard)) {
        return;
      }

      await _favoriteTokensBox.add(tokenStandard.toString());
    } on AddingToFavoriteTokensException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AddingToFavoriteTokensException(cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> remove(TokenStandard tokenStandard) async {
    try {
      final int index = _favoriteTokensBox.values.toList().indexOf(
        tokenStandard.toString(),
      );
      if (index == -1) {
        return;
      }

      await _favoriteTokensBox.deleteAt(index);
    } on RemovingFromFavoriteTokensException {
      rethrow;
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        RemovingFromFavoriteTokensException(cause: error),
        stackTrace,
      );
    }
  }
}
