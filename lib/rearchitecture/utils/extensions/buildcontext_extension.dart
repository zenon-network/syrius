import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Extension on the [BuildContext] class
extension BuildContextExtensions on BuildContext {
  /// Getter method for easier access to the [AppLocalizations] instance
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
