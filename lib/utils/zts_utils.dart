import 'dart:ui';

import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

final List<Token> kDualCoin = <Token>[
  kZnnCoin,
  kQsrCoin,
];

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

final Map<TokenStandard, Color> kCoinIdColor = <TokenStandard, Color>{
  kZnnCoin.tokenStandard: AppColors.znnColor,
  kQsrCoin.tokenStandard: AppColors.qsrColor,
};

bool isTrustedToken(String tokenStandard) {
  return <String>[
    znnTokenStandard,
    qsrTokenStandard,
    ...Hive.box(kFavoriteTokensBox).values,
  ].contains(tokenStandard);
}
