import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

const DividerThemeData kDefaultDividerThemeData = DividerThemeData(
  thickness: 1.0,
  indent: 0.0,
  endIndent: 0.0,
  space: 1.0,
);

final ButtonStyle kElevatedButtonStyle = ElevatedButton.styleFrom(
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(
      6.0,
    ),
  ),
  minimumSize: const Size(55, 42),
  primary: AppColors.znnColor,
);

final ButtonStyle kOutlinedButtonStyle = OutlinedButton.styleFrom(
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(
      6.0,
    ),
  ),
  side: const BorderSide(
    color: AppColors.znnColor,
  ),
  textStyle: kOutlinedButtonTextStyle,
);

const TextStyle kText1TextStyle = TextStyle(
  fontSize: 14.0,
  fontWeight: FontWeight.w400,
);

const TextStyle kText2TextStyle = TextStyle(
  fontSize: 12.0,
  fontWeight: FontWeight.w400,
);

const TextStyle kHeadline6TextStyle = TextStyle(
  fontSize: 16.0,
  fontWeight: FontWeight.w400,
);

const TextStyle kHeadline5TextStyle = TextStyle(
  fontSize: 18.0,
  fontWeight: FontWeight.w400,
);

const TextStyle kHeadline4TextStyle = TextStyle(
  fontSize: 20.0,
  fontWeight: FontWeight.w400,
);

const TextStyle kHeadline2TextStyle = TextStyle(
  fontSize: 24.0,
  fontWeight: FontWeight.w500,
);

const TextStyle kHeadline1TextStyle = TextStyle(
  fontSize: 26.0,
  fontWeight: FontWeight.w500,
);

const TextStyle kOutlinedButtonTextStyle = TextStyle(
  fontSize: 16.0,
  fontWeight: FontWeight.w400,
);

const TextStyle kTextButtonTextStyle = TextStyle(
  fontSize: 10.0,
  fontWeight: FontWeight.w400,
);

const TextStyle kSubtitle1TextStyle = TextStyle(
  fontSize: 12.0,
  fontWeight: FontWeight.w400,
  color: AppColors.subtitleColor,
);

const TextStyle kSubtitle2TextStyle = TextStyle(
  fontSize: 10.0,
  fontWeight: FontWeight.w400,
  color: AppColors.subtitleColor,
);

final TextButtonThemeData kTextButtonThemeData = TextButtonThemeData(
  style: TextButton.styleFrom(
    textStyle: kTextButtonTextStyle,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    minimumSize: const Size(55.0, 25.0),
    backgroundColor: AppColors.znnColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        8.0,
      ),
    ),
  ),
);

const TextStyle kHintTextStyle = TextStyle(
  fontWeight: FontWeight.w400,
  fontSize: 14.0,
);

const TextStyle kTextFormFieldErrorStyle = TextStyle(
  color: AppColors.errorColor,
);

const OutlineInputBorder kOutlineInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(5.0)),
);

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    toggleableActiveColor: AppColors.znnColor,
    hoverColor: AppColors.lightTextFormFieldFill,
    textButtonTheme: kTextButtonThemeData,
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: kOutlinedButtonStyle.copyWith(
        foregroundColor: MaterialStateProperty.resolveWith(
          (states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.black38;
            }
            return Colors.black;
          },
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: kElevatedButtonStyle,
    ),
    backgroundColor: AppColors.backgroundLight,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.znnColor,
    ),
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.lightTextFormFieldFill,
      hintStyle: kHintTextStyle.copyWith(
        color: AppColors.lightHintTextColor,
      ),
      errorStyle: kTextFormFieldErrorStyle,
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
          width: 2.0,
        ),
      ),
      focusedErrorBorder: kOutlineInputBorder.copyWith(
        borderSide: const BorderSide(
          color: AppColors.errorColor,
          width: 2.0,
        ),
      ),
    ),
    dividerTheme: kDefaultDividerThemeData.copyWith(
      color: AppColors.lightDividerColor,
    ),
    colorScheme: const ColorScheme.light(
      primary: Colors.white,
      primaryContainer: AppColors.lightPrimaryContainer,
      secondary: AppColors.lightSecondary,
      secondaryContainer: AppColors.lightSecondaryContainer,
      error: AppColors.errorColor,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.lightSecondary,
    ),
    textTheme: TextTheme(
      bodyText1: kText1TextStyle.copyWith(
        color: Colors.black,
      ),
      bodyText2: kText2TextStyle.copyWith(
        color: Colors.black,
      ),
      subtitle1: kSubtitle1TextStyle,
      subtitle2: kSubtitle2TextStyle,
      headline6: kHeadline6TextStyle.copyWith(
        color: Colors.black,
      ),
      headline5: kHeadline5TextStyle.copyWith(
        color: Colors.black,
      ),
      headline4: kHeadline4TextStyle.copyWith(
        color: Colors.black,
      ),
      headline2: kHeadline2TextStyle.copyWith(
        color: Colors.black,
      ),
      headline1: kHeadline1TextStyle.copyWith(
        color: Colors.black,
      ),
    ),
    unselectedWidgetColor: AppColors.lightSecondaryContainer,
  );

  static final ThemeData darkTheme = ThemeData(
    toggleableActiveColor: AppColors.znnColor,
    hoverColor: AppColors.darkTextFormFieldFill,
    textButtonTheme: kTextButtonThemeData,
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: kOutlinedButtonStyle.copyWith(
        foregroundColor: MaterialStateProperty.resolveWith(
          (states) {
            if (states.contains(MaterialState.disabled)) {
              return Colors.white38;
            }
            return Colors.white;
          },
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: kElevatedButtonStyle,
    ),
    backgroundColor: AppColors.backgroundDark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: Colors.white.withOpacity(0.1),
      cursorColor: AppColors.znnColor,
    ),
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.darkTextFormFieldFill,
      hintStyle: kHintTextStyle.copyWith(
        color: AppColors.darkHintTextColor,
      ),
      errorStyle: kTextFormFieldErrorStyle,
      enabledBorder: kOutlineInputBorder.copyWith(
        borderSide: BorderSide.none,
      ),
      disabledBorder: kOutlineInputBorder.copyWith(
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      focusedBorder: kOutlineInputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.znnColor),
      ),
      errorBorder: kOutlineInputBorder.copyWith(
        borderSide: const BorderSide(
          color: AppColors.errorColor,
          width: 2.0,
        ),
      ),
      focusedErrorBorder: kOutlineInputBorder.copyWith(
        borderSide: const BorderSide(
          color: AppColors.errorColor,
          width: 2.0,
        ),
      ),
    ),
    dividerTheme: kDefaultDividerThemeData.copyWith(
      color: AppColors.darkDividerColor,
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      secondary: AppColors.darkSecondary,
      secondaryContainer: AppColors.darkSecondaryContainer,
      error: AppColors.errorColor,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.lightSecondary,
    ),
    textTheme: TextTheme(
      bodyText1: kText1TextStyle.copyWith(
        color: Colors.white,
      ),
      bodyText2: kText2TextStyle.copyWith(
        color: Colors.white,
      ),
      subtitle1: kSubtitle1TextStyle,
      subtitle2: kSubtitle2TextStyle,
      headline6: kHeadline6TextStyle.copyWith(
        color: Colors.white,
      ),
      headline5: kHeadline5TextStyle.copyWith(
        color: Colors.white,
      ),
      headline4: kHeadline4TextStyle.copyWith(
        color: AppColors.subtitleColor,
      ),
      headline2: kHeadline2TextStyle.copyWith(
        color: Colors.white,
      ),
      headline1: kHeadline2TextStyle.copyWith(
        color: Colors.white,
      ),
    ),
    unselectedWidgetColor: AppColors.darkSecondaryContainer,
  );

  AppTheme._();
}
