import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// The new light theme closer to the default Material ThemeData
final ThemeData newLightTheme = ThemeData(
  cardTheme: CardThemeData(
    //TODO: check if it's okay
    color: AppColors.darkPrimary,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.znnColor,
  ),
  dividerTheme: kDefaultDividerThemeData,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.znnColor,
      foregroundColor: Colors.white,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: AppColors.lightTextFormFieldFill,
    filled: true,
    errorStyle: kTextFormFieldErrorStyle,
    hintStyle: kHintTextStyle.copyWith(
      color: AppColors.lightHintTextColor,
    ),
    enabledBorder: kOutlineInputBorder.copyWith(
      borderSide: BorderSide.none,
    ),
    disabledBorder: kOutlineInputBorder.copyWith(
      borderSide: const BorderSide(color: AppColors.inactiveIconsGray),
    ),
    focusedBorder: kOutlineInputBorder.copyWith(
      borderSide: const BorderSide(color: AppColors.inactiveIconsGray),
    ),
    errorBorder: kOutlineInputBorder.copyWith(
      borderSide: const BorderSide(
        color: AppColors.errorColor,
        width: 2,
      ),
    ),
    focusedErrorBorder: kOutlineInputBorder.copyWith(
      borderSide: const BorderSide(
        color: AppColors.errorColor,
        width: 2,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(
        color: AppColors.znnColor,
      ),
    ),
  ),
  scaffoldBackgroundColor: AppColors.backgroundLight,
);

/// The new dark theme closer to the default Material ThemeData
final ThemeData newDarkTheme = ThemeData(
  brightness: Brightness.dark,
  cardTheme: CardThemeData(
    color: AppColors.darkPrimary,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: AppColors.znnColor,
  ),
  dividerTheme: kDefaultDividerThemeData,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.znnColor,
      foregroundColor: Colors.white,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: AppColors.darkTextFormFieldFill,
    filled: true,
    errorStyle: kTextFormFieldErrorStyle,
    hintStyle: kHintTextStyle.copyWith(
      color: AppColors.darkHintTextColor,
    ),
    enabledBorder: kOutlineInputBorder.copyWith(
      borderSide: BorderSide.none,
    ),
    disabledBorder: kOutlineInputBorder.copyWith(
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.1),
      ),
    ),
    focusedBorder: kOutlineInputBorder.copyWith(
      borderSide: const BorderSide(color: AppColors.znnColor),
    ),
    errorBorder: kOutlineInputBorder.copyWith(
      borderSide: const BorderSide(
        color: AppColors.errorColor,
        width: 2,
      ),
    ),
    focusedErrorBorder: kOutlineInputBorder.copyWith(
      borderSide: const BorderSide(
        color: AppColors.errorColor,
        width: 2,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(
        color: AppColors.znnColor,
      ),
    ),
  ),
  scaffoldBackgroundColor: AppColors.backgroundDark
);
