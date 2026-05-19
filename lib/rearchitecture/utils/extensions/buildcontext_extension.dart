import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/new_app_themes.dart';

/// Extension on the [BuildContext] class
extension BuildContextExtension on BuildContext {
  /// Getter method for easier access to the [AppLocalizations] instance
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Returns the current ThemeData
  ThemeData get themeData => Theme.of(this);

  /// Returns the current TextTheme
  TextTheme get textTheme => themeData.textTheme;

  /// Whether the app is currently in dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Return the current new theme data
  //TODO(maznnwell): to be deleted/replaced
  ThemeData get newThemeData => isDarkMode ? newDarkTheme : newLightTheme;
}
