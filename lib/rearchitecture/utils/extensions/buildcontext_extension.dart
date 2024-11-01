import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Extension on the [BuildContext] class
extension BuildContextExtension on BuildContext {
  /// Getter method for easier access to the [AppLocalizations] instance
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Returns the current ThemeData
  ThemeData get theme => Theme.of(this);

  /// Returns the current TextTheme
  TextTheme get textTheme => theme.textTheme;

  /// Whether the app is currently in dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
