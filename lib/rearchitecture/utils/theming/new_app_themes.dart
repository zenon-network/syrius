import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

final ElevatedButtonThemeData _kElevatedButtonThemeData =
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.znnColor,
        disabledMouseCursor: SystemMouseCursors.forbidden,
        enabledMouseCursor: SystemMouseCursors.click,
        foregroundColor: const Color(0xFF0A140E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );

final FilledButtonThemeData _kFilledButtonThemeData = FilledButtonThemeData(
  style: FilledButton.styleFrom(
    disabledMouseCursor: SystemMouseCursors.forbidden,
    enabledMouseCursor: SystemMouseCursors.click,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
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

/// The new light theme aligned with the Syrius redesign tokens.
final ThemeData newLightTheme = ThemeData(
  useMaterial3: true,
  extensions: const <ThemeExtension<dynamic>>[SyriusThemeTokens.light],
  cardTheme: CardThemeData(
    color: SyriusThemeTokens.light.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: SyriusThemeTokens.light.border),
    ),
  ),
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.znnColor,
    surface: SyriusThemeTokens.light.surface,
  ),
  dividerTheme: kDefaultDividerThemeData.copyWith(
    color: SyriusThemeTokens.light.border,
  ),
  elevatedButtonTheme: _kElevatedButtonThemeData,
  filledButtonTheme: _kFilledButtonThemeData,
  iconButtonTheme: _kIconButtonThemeData,
  inputDecorationTheme: InputDecorationTheme(
    fillColor: SyriusThemeTokens.light.surfaceElevated,
    filled: true,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    errorStyle: kTextFormFieldErrorStyle,
    hintStyle: kHintTextStyle.copyWith(
      color: SyriusThemeTokens.light.textMuted,
    ),
    enabledBorder: kOutlineInputBorder.copyWith(
      borderSide: BorderSide(color: SyriusThemeTokens.light.border),
    ),
    disabledBorder: kOutlineInputBorder.copyWith(
      borderSide: BorderSide(color: SyriusThemeTokens.light.border),
    ),
    focusedBorder: kOutlineInputBorder.copyWith(
      borderSide: BorderSide(color: SyriusThemeTokens.light.borderStrong),
    ),
    errorBorder: kOutlineInputBorder.copyWith(
      borderSide: const BorderSide(
        color: AppColors.errorColor,
        width: 1.5,
      ),
    ),
    focusedErrorBorder: kOutlineInputBorder.copyWith(
      borderSide: const BorderSide(
        color: AppColors.errorColor,
        width: 1.5,
      ),
    ),
    iconColor: SyriusThemeTokens.light.znnGreen,
    prefixIconColor: SyriusThemeTokens.light.textMuted,
    suffixIconColor: SyriusThemeTokens.light.textSecondary,
  ),
  outlinedButtonTheme: _kOutlinedButtonThemeData,
  scaffoldBackgroundColor: SyriusThemeTokens.light.shellBackground,
  textButtonTheme: _kTextButtonThemeData,
);

/// The new dark theme aligned with the Syrius redesign tokens.
final ThemeData newDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  extensions: const <ThemeExtension<dynamic>>[SyriusThemeTokens.dark],
  cardTheme: CardThemeData(
    color: SyriusThemeTokens.dark.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: SyriusThemeTokens.dark.border),
    ),
  ),
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: AppColors.znnColor,
    surface: SyriusThemeTokens.dark.surface,
  ),
  dividerTheme: kDefaultDividerThemeData.copyWith(
    color: SyriusThemeTokens.dark.border,
  ),
  elevatedButtonTheme: _kElevatedButtonThemeData,
  filledButtonTheme: _kFilledButtonThemeData,
  iconButtonTheme: _kIconButtonThemeData,
  inputDecorationTheme: InputDecorationTheme(
    fillColor: SyriusThemeTokens.dark.surfaceElevated,
    filled: true,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    errorStyle: kTextFormFieldErrorStyle,
    hintStyle: kHintTextStyle.copyWith(
      color: SyriusThemeTokens.dark.textMuted,
    ),
    enabledBorder: kOutlineInputBorder.copyWith(
      borderSide: BorderSide(color: SyriusThemeTokens.dark.border),
    ),
    disabledBorder: kOutlineInputBorder.copyWith(
      borderSide: BorderSide(color: SyriusThemeTokens.dark.border),
    ),
    focusedBorder: kOutlineInputBorder.copyWith(
      borderSide: BorderSide(color: SyriusThemeTokens.dark.borderStrong),
    ),
    errorBorder: kOutlineInputBorder.copyWith(
      borderSide: const BorderSide(
        color: AppColors.errorColor,
        width: 1.5,
      ),
    ),
    focusedErrorBorder: kOutlineInputBorder.copyWith(
      borderSide: const BorderSide(
        color: AppColors.errorColor,
        width: 1.5,
      ),
    ),
    iconColor: SyriusThemeTokens.dark.znnGreen,
    prefixIconColor: SyriusThemeTokens.dark.textMuted,
    suffixIconColor: SyriusThemeTokens.dark.textSecondary,
  ),
  outlinedButtonTheme: _kOutlinedButtonThemeData,
  scaffoldBackgroundColor: SyriusThemeTokens.dark.shellBackground,
  textButtonTheme: _kTextButtonThemeData,
);
