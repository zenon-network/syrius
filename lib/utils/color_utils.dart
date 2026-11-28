import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/plasma_tier_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Utilities for deriving colors for tokens and plasma levels.
class ColorUtils {
  /// Returns the display [Color] for [tokenStandard], deriving a deterministic
  /// RGB color from its ZTS bytes when not predefined.
  static Color getTokenColor(TokenStandard tokenStandard) {
    return kCoinIdColor[tokenStandard] ??
        getColorFromHexCode(_getHexCodeFromTokenZts(tokenStandard));
  }

  /// Converts a 6-digit hexadecimal RGB [hexCode] into an opaque [Color].
  static Color getColorFromHexCode(String hexCode) {
    return Color(int.parse(hexCode, radix: 16) + 0xFF000000);
  }

  static String _getHexCodeFromTokenZts(TokenStandard tokenStandard) {
    final List<int> bytes =
        tokenStandard.getBytes().sublist(tokenStandard.getBytes().length - 3);
    return BytesUtils.bytesToHex(bytes);
  }

  /// Returns a status [Color] corresponding to the plasma tier of [plasmaInfo].
  static Color getPlasmaColor(PlasmaInfo plasmaInfo) {
    return switch (classifyPlasmaTier(plasmaInfo.currentPlasma)) {
      PlasmaTier.high => AppColors.znnColor,
      PlasmaTier.average => Colors.yellow,
      PlasmaTier.low => Colors.orange,
      PlasmaTier.insufficient => AppColors.ztsColor,
    };
  }
}
