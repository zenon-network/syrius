import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

final ElevatedButtonThemeData _kElevatedButtonThemeData =
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.znnColor,
        disabledMouseCursor: SystemMouseCursors.forbidden,
        enabledMouseCursor: SystemMouseCursors.click,
        foregroundColor: Colors.white,
      ),
    );

final FilledButtonThemeData _kFilledButtonThemeData = FilledButtonThemeData(
  style: FilledButton.styleFrom(
    disabledMouseCursor: SystemMouseCursors.forbidden,
    enabledMouseCursor: SystemMouseCursors.click,
  ),
);

final IconButtonThemeData _kIconButtonThemeData = IconButtonThemeData(
  style: FilledButton.styleFrom(
    disabledMouseCursor: SystemMouseCursors.forbidden,
    enabledMouseCursor: SystemMouseCursors.click,
  ),
);

final OutlinedButtonThemeData _kOutlinedButtonThemeData =
    OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        disabledMouseCursor: SystemMouseCursors.forbidden,
        enabledMouseCursor: SystemMouseCursors.click,
        side: const BorderSide(
          color: AppColors.znnColor,
        ),
      ),
    );

final TextButtonThemeData _kTextButtonThemeData = TextButtonThemeData(
  style: TextButton.styleFrom(
    disabledMouseCursor: SystemMouseCursors.forbidden,
    enabledMouseCursor: SystemMouseCursors.click,
  ),
);

/// The new light theme closer to the default Material ThemeData
final ThemeData newLightTheme = ThemeData(
  cardTheme: CardThemeData(
    //TODO(maznnwell): check if it's okay
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
  elevatedButtonTheme: _kElevatedButtonThemeData,
  filledButtonTheme: _kFilledButtonThemeData,
  iconButtonTheme: _kIconButtonThemeData,
  inputDecorationTheme: InputDecorationTheme(
    fillColor: AppColors.lightTextFormFieldFill,
    filled: true,
    floatingLabelBehavior: FloatingLabelBehavior.always,
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
    iconColor: AppColors.znnColor,
    prefixIconColor: AppColors.znnColor,
    suffixIconColor: AppColors.znnColor,
  ),
  outlinedButtonTheme: _kOutlinedButtonThemeData,
  scaffoldBackgroundColor: AppColors.backgroundLight,
  textButtonTheme: _kTextButtonThemeData,
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
  elevatedButtonTheme: _kElevatedButtonThemeData,
  filledButtonTheme: _kFilledButtonThemeData,
  iconButtonTheme: _kIconButtonThemeData,
  inputDecorationTheme: InputDecorationTheme(
    fillColor: AppColors.darkTextFormFieldFill,
    filled: true,
    floatingLabelBehavior: FloatingLabelBehavior.always,
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
    iconColor: AppColors.znnColor,
    prefixIconColor: AppColors.znnColor,
    suffixIconColor: AppColors.znnColor,
  ),
  outlinedButtonTheme: _kOutlinedButtonThemeData,
  scaffoldBackgroundColor: AppColors.backgroundDark,
  textButtonTheme: _kTextButtonThemeData,
);
