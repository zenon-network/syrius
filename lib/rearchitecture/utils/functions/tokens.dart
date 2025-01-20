import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Takes in a list of assets - tokens and coins - and returns a list with the
/// coins at the beginning of the list
///
/// If no coins are found in the list, then the order is preserved
List<Token> sortAssets(List<Token> assets) {
  assets.sort((Token a, Token b) {
    if (a.isCoin && !b.isCoin) return -1; // Coins come first
    if (!a.isCoin && b.isCoin) return 1;  // Tokens come second
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
