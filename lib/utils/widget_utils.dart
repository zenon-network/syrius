import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_display/model/display_settings_enums.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/app_theme_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/text_scaling_notifier.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class WidgetUtils {
  static void setThemeMode(BuildContext context) {
    final AppThemeNotifier appThemeNotifier = Provider.of<AppThemeNotifier>(
      context,
      listen: false,
    );
    final ThemeMode savedThemeMode = ThemeMode.values.firstWhere(
      (ThemeMode element) =>
          element.toString() == sharedPrefsService!.get(kThemeModeKey),
      orElse: () => kDefaultThemeMode,
    );
    if (appThemeNotifier.currentThemeMode != savedThemeMode) {
      appThemeNotifier.changeThemeMode(savedThemeMode);
    }
  }

  static void setTextScale(BuildContext context) {
    final TextScalingNotifier textScalingNotifier =
        Provider.of<TextScalingNotifier>(
      context,
      listen: false,
    );

    final TextScaling savedTextScaling = TextScaling.values.firstWhere(
      (TextScaling element) =>
          element.toString() == sharedPrefsService!.get(kTextScalingKey),
      orElse: () => kDefaultTextScaling,
    );
    if (textScalingNotifier.currentTextScaling != savedTextScaling) {
      textScalingNotifier.changeTextScaling(savedTextScaling);
    }
  }

  static String isWidgetHiddenKey(String widgetTitle) =>
      '${widgetTitle}is_hidden';

  static String getPlasmaToolTipMessage(PlasmaInfo plasmaInfo) {
    if (plasmaInfo.currentPlasma >= kPillarPlasmaAmountNeeded) {
      return 'High Plasma';
    } else if (plasmaInfo.currentPlasma >= kIssueTokenPlasmaAmountNeeded &&
        plasmaInfo.currentPlasma < kPillarPlasmaAmountNeeded) {
      return 'Average Plasma';
    } else if (plasmaInfo.currentPlasma >= minPlasmaAmount.toInt() &&
        plasmaInfo.currentPlasma < kIssueTokenPlasmaAmountNeeded) {
      return 'Low Plasma';
    } else {
      return 'Insufficient Plasma';
    }
  }
}
