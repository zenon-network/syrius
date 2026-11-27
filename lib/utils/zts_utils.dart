import 'dart:ui';

import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Native dual-coin tokens (ZNN and QSR).
final List<Token> kDualCoin = <Token>[
  kZnnCoin,
  kQsrCoin,
];

/// Static [Token] metadata for native ZNN.
final Token kZnnCoin = Token.fromJson(
  <String, dynamic>{
    'name': 'ZNN',
    'symbol': 'ZNN',
    'domain': 'zenon.network',
    'totalSupply': '1190555916718187',
    'decimals': 8,
    'owner': 'z1qxemdeddedxt0kenxxxxxxxxxxxxxxxxh9amk0',
    'tokenStandard': 'zts1znnxxxxxxxxxxxxx9z4ulx',
    'maxSupply': '9007199254740991',
    'isBurnable': true,
    'isMintable': true,
    'isUtility': true,
  },
);

/// Static [Token] metadata for native QSR.
final Token kQsrCoin = Token.fromJson(
  <String, dynamic>{
    'name': 'QSR',
    'symbol': 'QSR',
    'domain': 'zenon.network',
    'totalSupply': '3049289789638539',
    'decimals': 8,
    'owner': 'z1qxemdeddedxt0kenxxxxxxxxxxxxxxxxh9amk0',
    'tokenStandard': 'zts1qsrxxxxxxxxxxxxxmrhjll',
    'maxSupply': '9007199254740991',
    'isBurnable': true,
    'isMintable': true,
    'isUtility': true,
  },
);

/// Brand color lookup for native ZNN and QSR token standards.
final Map<TokenStandard, Color> kCoinIdColor = <TokenStandard, Color>{
  kZnnCoin.tokenStandard: AppColors.znnColor,
  kQsrCoin.tokenStandard: AppColors.qsrColor,
};

/// Returns `true` if [tokenStandard] is ZNN, QSR, or a user-favorited token.
bool isTrustedToken(String tokenStandard) {
  return <String>[
    znnTokenStandard,
    qsrTokenStandard,
    ...Hive.box(kFavoriteTokensBox).values,
  ].contains(tokenStandard);
}
