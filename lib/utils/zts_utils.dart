import 'dart:ui';

import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

final List<Token> kDualCoin = [
  kZnnCoin,
  kQsrCoin,
];

final Token kZnnCoin = Token(
  'Zenon',
  'ZNN',
  'zenon.network',
  0,
  znnDecimals,
  pillarAddress,
  TokenStandard.parse(znnTokenStandard),
  0,
  true,
  true,
  true,
);
final Token kQsrCoin = Token(
  'Quasar',
  'QSR',
  'zenon.network',
  0,
  qsrDecimals,
  stakeAddress,
  TokenStandard.parse(qsrTokenStandard),
  0,
  true,
  true,
  true,
);

final Map<TokenStandard, Color> kCoinIdColor = {
  kZnnCoin.tokenStandard: AppColors.znnColor,
  kQsrCoin.tokenStandard: AppColors.qsrColor,
};
