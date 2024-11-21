import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/app_theme_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/text_scaling_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
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

  static InfiniteScrollTableCell getMarqueeAddressTableCell(
    Address? address,
    BuildContext context,
  ) {
    final TextStyle? textStyle = address != null && address.isEmbedded()
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.znnColor,
              fontWeight: FontWeight.bold,
            )
        : null;

    if (address != null && kAddressLabelMap.containsKey(address.toString())) {
      return InfiniteScrollTableCell.tooltipWithMarquee(
        address,
        textStyle: textStyle,
        flex: 2,
      );
    } else {
      return InfiniteScrollTableCell.withMarquee(
        address != null ? address.toString() : '',
        textStyle: textStyle,
        flex: 2,
      );
    }
  }

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

  static InfiniteScrollTableCell getTextAddressTableCell(
    Address? address,
    BuildContext context, {
    bool checkIfStakeAddress = false,
    bool isShortVersion = true,
    bool showCopyToClipboardIcon = false,
  }) {
    final TextStyle? textStyle = address != null && address.isEmbedded() ||
            (checkIfStakeAddress && address.toString() == kSelectedAddress)
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.znnColor,
              fontWeight: FontWeight.bold,
            )
        : null;

    if (address != null && kAddressLabelMap.containsKey(address.toString())) {
      return InfiniteScrollTableCell.tooltipWithText(
        context,
        address,
        textStyle: textStyle,
        flex: 2,
        showCopyToClipboardIcon: showCopyToClipboardIcon,
      );
    } else {
      return InfiniteScrollTableCell.withText(
        context,
        address != null
            ? isShortVersion
                ? address.toShortString()
                : address.toString()
            : '',
        flex: 2,
        textStyle: textStyle,
        showCopyToClipboardIcon: showCopyToClipboardIcon,
      );
    }
  }
}
