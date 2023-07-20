import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ColorUtils {
  static Color getTokenColor(TokenStandard tokenStandard) {
    return kCoinIdColor[tokenStandard] ??
        getColorFromHexCode(_getHexCodeFromTokenZts(tokenStandard));
  }

  static Color getColorFromHexCode(String hexCode) {
    return Color(int.parse(hexCode, radix: 16) + 0xFF000000);
  }

  static String _getHexCodeFromTokenZts(TokenStandard tokenStandard) {
    List<int> bytes =
        tokenStandard.getBytes().sublist(tokenStandard.getBytes().length - 3);
    return BytesUtils.bytesToHex(bytes);
  }

  static Color getPlasmaColor(PlasmaInfo plasmaInfo) {
    if (plasmaInfo.currentPlasma >= kPillarPlasmaAmountNeeded) {
      return AppColors.znnColor;
    } else if (plasmaInfo.currentPlasma >= kIssueTokenPlasmaAmountNeeded &&
        plasmaInfo.currentPlasma < kPillarPlasmaAmountNeeded) {
      return Colors.yellow;
    } else if (plasmaInfo.currentPlasma >= minPlasmaAmount.toInt() &&
        plasmaInfo.currentPlasma < kIssueTokenPlasmaAmountNeeded) {
      return Colors.orange;
    } else {
      return AppColors.ztsColor;
    }
  }
}
