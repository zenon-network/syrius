import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Takes in a list of assets - tokens and coins - and returns a list with the
/// coins at the beginning of the list
///
/// If no coins are found in the list, then the order is preserved
List<Token> sortAssets(List<Token> assets) {
  assets.sort((Token a, Token b) {
    if (a.isCoin && !b.isCoin) return -1; // Coins come first
    if (!a.isCoin && b.isCoin) return 1; // Tokens come second
    if (a.isCoin && b.isCoin) {
      if (a.tokenStandard == znnZts) {
        return -1; // Zenon comes first
      } else {
        return 1; // Quasar comes second
      }
    }
    return 0; // Preserve original order within the same type
  });
  return assets;
}

/// Returns the account's tokens that have a positive balance.
List<Token> getTokensWithBalance({
  required AccountInfo accountInfo,
}) {
  final List<Token> tokens = <Token>[];
  final List<BalanceInfoListItem> balanceInfoList =
      accountInfo.balanceInfoList!;

  for (final BalanceInfoListItem balanceInfo in balanceInfoList) {
    final BigInt balance = balanceInfo.balance!;
    final Token token = balanceInfo.token!;
    if (balance > BigInt.zero) {
      tokens.add(token);
    }
  }

  return tokens;
}

/// Replaces [list] with the sorted union of initial and funded tokens.
void fillAvailableTokens({
  required List<Token> initialTokens,
  required List<Token> list,
  required List<Token> tokensWithBalance,
}) {
  final List<Token> emptyList = <Token>[...tokensWithBalance];

  // The available tokens should always contain the initialTokens
  for (final Token token in initialTokens) {
    if (!emptyList.contains(token)) {
      emptyList.insert(0, token);
    }
  }

  list
    ..clear()
    ..addAll(sortAssets(emptyList));
}
