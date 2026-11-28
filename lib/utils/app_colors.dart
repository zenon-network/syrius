import 'package:flutter/material.dart';

/// Brand, semantic, and surface color palette constants for Syrius.
class AppColors {
  /// Primary ZNN brand green accent color.
  static const Color znnColor = Color(0xFF4FD166);

  /// Primary QSR brand blue accent color.
  static const Color qsrColor = Color(0xFF006AFF);

  /// Accent magenta color used for generic ZTS tokens.
  static const Color ztsColor = Color(0xFFFC54AE);

  /// Error and destructive action highlight color.
  static const Color errorColor = Color(0xFFF40442);

  /// Scaffold background color in light mode.
  static const Color backgroundLight = Color(0xFFEAEAEA);

  /// Scaffold background color in dark mode.
  static const Color backgroundDark = Color(0xFF1B1C1B);

  /// Muted foreground color for secondary labels and subtitles.
  static const Color subtitleColor = Color(0xFFA0A5A0);

  /// Border color for the "Max" amount button.
  static const Color maxAmountBorder = Color(0xFF353735);

  /// Secondary foreground color in light mode.
  static const Color lightSecondary = Color(0xFF5D635D);

  /// Secondary container color in light mode.
  static const Color lightSecondaryContainer = Color(0xFFEEF0EE);

  /// Secondary foreground color in dark mode.
  static const Color darkSecondary = Color(0xFF353735);

  /// Secondary container color in dark mode.
  static const Color darkSecondaryContainer = Color(0xFF2E302E);

  /// Warning/alert notification accent color.
  static const Color alertNotification = Color(0xFFE6B543);

  /// Container fill color on the wallet access screen.
  static const Color accessWalletContainersGray = Color(0xFF262726);

  /// Neutral gray used for inactive icons and borders.
  static const Color inactiveIconsGray = Color(0xFF353735);

  /// Primary surface color in dark mode.
  static const Color darkPrimary = Color(0xFF262726);

  /// Primary container surface color in dark mode.
  static const Color darkPrimaryContainer = Color(0xFF2E302E);

  /// Primary container surface color in light mode.
  static const Color lightPrimaryContainer = Color(0xFFF6F7F6);

  /// Divider line color in light mode.
  static const Color lightDividerColor = Color(0xFFD5D8D5);

  /// Divider line color in dark mode.
  static const Color darkDividerColor = Color(0xFF353735);

  /// Fill color for text form fields in light mode.
  static const Color lightTextFormFieldFill = Color(0xFFFFFFFF);

  /// Fill color for text form fields in dark mode.
  static const Color darkTextFormFieldFill = Color(0xFF2E302E);

  /// Hint text color in dark mode.
  static const Color darkHintTextColor = Color(0xFF6E736E);

  /// Hint text color in light mode.
  static const Color lightHintTextColor = Color(0xFF888E88);

  /// Underline border color for seed phrase input cells.
  static const Color seedUnderlineBorderColor = Color.fromRGBO(99, 99, 99, 1);

  /// Background color for unselected seed phrase word choices.
  static const Color unselectedSeedChoiceColor = Color(0xFF636363);

  /// Background color for selected seed phrase word choices.
  static const Color selectedSeedChoiceColor = Color(0xFF292929);
}
