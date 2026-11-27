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
  static const Color backgroundDark = Color(0xFF1E1E1E);

  /// Muted foreground color for secondary labels and subtitles.
  static const Color subtitleColor = Color(0xFFB3B3B3);

  /// Border color for the "Max" amount button.
  static const Color maxAmountBorder = Color(0xFF474747);

  /// Secondary foreground color in light mode.
  static const Color lightSecondary = Color(0xFFB3B3B3);

  /// Secondary container color in light mode.
  static const Color lightSecondaryContainer = Color(0xFF545454);

  /// Secondary foreground color in dark mode.
  static const Color darkSecondary = Color(0xFF3F3F3F);

  /// Secondary container color in dark mode.
  static const Color darkSecondaryContainer = Color.fromRGBO(46, 46, 46, 1);

  /// Warning/alert notification accent color.
  static const Color alertNotification = Color(0xFFDAE240);

  /// Container fill color on the wallet access screen.
  static const Color accessWalletContainersGray = Color.fromRGBO(46, 46, 46, 1);

  /// Neutral gray used for inactive icons and borders.
  static const Color inactiveIconsGray = Color.fromRGBO(51, 51, 51, 1);

  /// Primary surface color in dark mode.
  static const Color darkPrimary = Color(0xFF262626);

  /// Primary container surface color in dark mode.
  static const Color darkPrimaryContainer = Color(0xFF2D2D2D);

  /// Primary container surface color in light mode.
  static const Color lightPrimaryContainer = Color(0xFFF4FEFF);

  /// Divider line color in light mode.
  static const Color lightDividerColor = Color.fromRGBO(193, 193, 193, 0.8);

  /// Divider line color in dark mode.
  static const Color darkDividerColor = Color(0xFF333333);

  /// Fill color for text form fields in light mode.
  static const Color lightTextFormFieldFill = Color(0xFFE4E4E4);

  /// Fill color for text form fields in dark mode.
  static const Color darkTextFormFieldFill = Color.fromRGBO(51, 51, 51, 1);

  /// Hint text color in dark mode.
  static const Color darkHintTextColor = Color.fromRGBO(99, 99, 99, 1);

  /// Hint text color in light mode.
  static const Color lightHintTextColor = Color.fromRGBO(179, 179, 179, 1);

  /// Underline border color for seed phrase input cells.
  static const Color seedUnderlineBorderColor = Color.fromRGBO(99, 99, 99, 1);

  /// Background color for unselected seed phrase word choices.
  static const Color unselectedSeedChoiceColor = Color(0xFF636363);

  /// Background color for selected seed phrase word choices.
  static const Color selectedSeedChoiceColor = Color(0xFF292929);
}
