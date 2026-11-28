import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// Default divider styling shared across light and dark themes.
const DividerThemeData kDefaultDividerThemeData = DividerThemeData(
  thickness: 1,
  indent: 0,
  endIndent: 0,
  space: 1,
);

/// Default styling for primary [ElevatedButton] widgets.
final ButtonStyle kElevatedButtonStyle = ElevatedButton.styleFrom(
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(999),
  ),
  minimumSize: const Size(55, 40),
  backgroundColor: AppColors.znnColor,
  foregroundColor: const Color(0xFF0A140E),
);

/// Default styling for [OutlinedButton] widgets.
final ButtonStyle kOutlinedButtonStyle = OutlinedButton.styleFrom(
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(999),
  ),
  side: const BorderSide(
    color: AppColors.znnColor,
  ),
  textStyle: kOutlinedButtonTextStyle,
);

/// Small display text style used in compact headers.
const TextStyle kDisplaySmallTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
);

/// Large body text style.
const TextStyle kBodyLargeTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
);

/// Medium body text style.
const TextStyle kBodyMediumTextStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
);

/// Small body text style.
const TextStyle kBodySmallTextStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w300,
);

/// Large headline text style.
const TextStyle kHeadlineLargeTextStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.w500,
);

/// Medium headline text style.
const TextStyle kHeadlineMediumTextStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w500,
);

/// Small headline text style.
const TextStyle kHeadlineSmallTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
);

/// Text style used inside [OutlinedButton] labels.
const TextStyle kOutlinedButtonTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
);

/// Text style used inside [TextButton] labels.
const TextStyle kTextButtonTextStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w400,
);

/// Medium title text style using the secondary subtitle color.
const TextStyle kTitleMediumTextStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: AppColors.subtitleColor,
);

/// Small title text style using the secondary subtitle color.
const TextStyle kTitleSmallTextStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w400,
  color: AppColors.subtitleColor,
);

/// Default theme configuration for [TextButton] widgets.
final TextButtonThemeData kTextButtonThemeData = TextButtonThemeData(
  style: TextButton.styleFrom(
    textStyle: kTextButtonTextStyle,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: const Size(55, 25),
    backgroundColor: AppColors.znnColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        8,
      ),
    ),
  ),
);

/// Base text style for form input hints.
const TextStyle kHintTextStyle = TextStyle(
  fontWeight: FontWeight.w400,
  fontSize: 14,
);

/// Text style for validation errors on text form fields.
const TextStyle kTextFormFieldErrorStyle = TextStyle(
  color: AppColors.errorColor,
);

/// Default rounded outline border for text input fields.
const OutlineInputBorder kOutlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(10)),
);

/// Light and dark [ThemeData] definitions for Syrius.
class AppTheme {

  AppTheme._();

  /// Light mode application theme.
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    extensions: const <ThemeExtension<dynamic>>[SyriusThemeTokens.light],
    hoverColor: SyriusThemeTokens.light.surfaceSubtle,
    dialogTheme: DialogThemeData(
      backgroundColor: SyriusThemeTokens.light.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: SyriusThemeTokens.light.border),
      ),
    ),
    cardTheme: CardThemeData(
      color: SyriusThemeTokens.light.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: SyriusThemeTokens.light.border),
      ),
    ),
    textButtonTheme: kTextButtonThemeData,
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: kOutlinedButtonStyle.copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.black38;
            }
            return SyriusThemeTokens.light.textPrimary;
          },
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: kElevatedButtonStyle,
    ),
    scaffoldBackgroundColor: SyriusThemeTokens.light.shellBackground,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: SyriusThemeTokens.light.znnGreen,
      selectionHandleColor: SyriusThemeTokens.light.znnGreen,
    ),
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      fillColor: SyriusThemeTokens.light.surfaceElevated,
      hintStyle: kHintTextStyle.copyWith(
        color: SyriusThemeTokens.light.textMuted,
      ),
      errorStyle: kTextFormFieldErrorStyle,
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
    ),
    dividerTheme: kDefaultDividerThemeData.copyWith(
      color: SyriusThemeTokens.light.border,
    ),
    iconTheme: IconThemeData(
      color: SyriusThemeTokens.light.textSecondary,
    ),
    textTheme: TextTheme(
      bodyLarge: kBodyLargeTextStyle.copyWith(
        color: SyriusThemeTokens.light.textPrimary,
      ),
      bodyMedium: kBodyMediumTextStyle.copyWith(
        color: SyriusThemeTokens.light.textPrimary,
      ),
      bodySmall: kBodySmallTextStyle.copyWith(
        color: SyriusThemeTokens.light.textSecondary,
      ),
      titleMedium: kTitleMediumTextStyle.copyWith(
        color: SyriusThemeTokens.light.textSecondary,
      ),
      titleSmall: kTitleSmallTextStyle.copyWith(
        color: SyriusThemeTokens.light.textMuted,
      ),
      headlineLarge: kHeadlineLargeTextStyle.copyWith(
        color: SyriusThemeTokens.light.textPrimary,
      ),
      headlineMedium: kHeadlineMediumTextStyle.copyWith(
        color: SyriusThemeTokens.light.textPrimary,
      ),
      headlineSmall: kHeadlineSmallTextStyle.copyWith(
        color: SyriusThemeTokens.light.textPrimary,
      ),
    ),
    unselectedWidgetColor: SyriusThemeTokens.light.textMuted,
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF0A140E);
          }
          return SyriusThemeTokens.light.textPrimary;
        },
      ),
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.znnColor;
          }
          return SyriusThemeTokens.light.border;
        },
      ),
      trackOutlineColor: const WidgetStatePropertyAll<Color>(
        Colors.transparent,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return AppColors.znnColor;
        }
        return null;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: BorderSide(color: SyriusThemeTokens.light.borderStrong),
      fillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return AppColors.znnColor;
        }
        return null;
      }),
      checkColor: const WidgetStatePropertyAll<Color>(Color(0xFF0A140E)),
    ),
    colorScheme: ColorScheme.light(
      primary: SyriusThemeTokens.light.surface,
      primaryContainer: SyriusThemeTokens.light.surfaceElevated,
      secondary: SyriusThemeTokens.light.textSecondary,
      secondaryContainer: SyriusThemeTokens.light.surfaceSubtle,
      error: AppColors.errorColor,
    ).copyWith(surface: SyriusThemeTokens.light.shellBackground),
  );

  /// Dark mode application theme.
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    extensions: const <ThemeExtension<dynamic>>[SyriusThemeTokens.dark],
    hoverColor: SyriusThemeTokens.dark.surfaceElevated,
    dialogTheme: DialogThemeData(
      backgroundColor: SyriusThemeTokens.dark.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: SyriusThemeTokens.dark.border),
      ),
    ),
    cardTheme: CardThemeData(
      color: SyriusThemeTokens.dark.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: SyriusThemeTokens.dark.border),
      ),
    ),
    textButtonTheme: kTextButtonThemeData,
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: kOutlinedButtonStyle.copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.white38;
            }
            return SyriusThemeTokens.dark.textPrimary;
          },
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: kElevatedButtonStyle,
    ),
    scaffoldBackgroundColor: SyriusThemeTokens.dark.shellBackground,
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Colors.white.withValues(alpha: 0.12),
      cursorColor: AppColors.znnColor,
      selectionHandleColor: AppColors.znnColor,
    ),
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      fillColor: SyriusThemeTokens.dark.surfaceElevated,
      hintStyle: kHintTextStyle.copyWith(
        color: SyriusThemeTokens.dark.textMuted,
      ),
      errorStyle: kTextFormFieldErrorStyle,
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
    ),
    dividerTheme: kDefaultDividerThemeData.copyWith(
      color: SyriusThemeTokens.dark.border,
    ),
    iconTheme: IconThemeData(
      color: SyriusThemeTokens.dark.textSecondary,
    ),
    textTheme: TextTheme(
      bodyLarge: kBodyLargeTextStyle.copyWith(
        color: SyriusThemeTokens.dark.textPrimary,
      ),
      bodyMedium: kBodyMediumTextStyle.copyWith(
        color: SyriusThemeTokens.dark.textPrimary,
      ),
      bodySmall: kBodySmallTextStyle.copyWith(
        color: SyriusThemeTokens.dark.textSecondary,
      ),
      titleMedium: kTitleMediumTextStyle.copyWith(
        color: SyriusThemeTokens.dark.textSecondary,
      ),
      titleSmall: kTitleSmallTextStyle.copyWith(
        color: SyriusThemeTokens.dark.textMuted,
      ),
      headlineLarge: kHeadlineLargeTextStyle.copyWith(
        color: SyriusThemeTokens.dark.textPrimary,
      ),
      headlineMedium: kHeadlineMediumTextStyle.copyWith(
        color: SyriusThemeTokens.dark.textPrimary,
      ),
      headlineSmall: kHeadlineSmallTextStyle.copyWith(
        color: SyriusThemeTokens.dark.textPrimary,
      ),
    ),
    unselectedWidgetColor: SyriusThemeTokens.dark.textMuted,
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF0A140E);
          }
          return SyriusThemeTokens.dark.textPrimary;
        },
      ),
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.znnColor;
          }
          return SyriusThemeTokens.dark.border;
        },
      ),
      trackOutlineColor: const WidgetStatePropertyAll<Color>(
        Colors.transparent,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return AppColors.znnColor;
        }
        return null;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: BorderSide(color: SyriusThemeTokens.dark.borderStrong),
      fillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return AppColors.znnColor;
        }
        return null;
      }),
      checkColor: const WidgetStatePropertyAll<Color>(Color(0xFF0A140E)),
    ),
    colorScheme: ColorScheme.dark(
      primary: SyriusThemeTokens.dark.surface,
      primaryContainer: SyriusThemeTokens.dark.surfaceElevated,
      secondary: SyriusThemeTokens.dark.textSecondary,
      secondaryContainer: SyriusThemeTokens.dark.surfaceElevated,
      error: AppColors.errorColor,
    ).copyWith(surface: SyriusThemeTokens.dark.shellBackground),
  );
}
