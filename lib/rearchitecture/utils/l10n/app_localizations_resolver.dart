import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';

/// Resolves an [AppLocalizations] instance without requiring a widget
/// [BuildContext].
///
/// Resolution order:
/// 1. Explicit [locale], if provided (falling back to language-only or the
///    first supported locale when unsupported).
/// 2. Live [AppLocalizations.of] from [context] or
///    [globalNavigatorKey], when mounted.
/// 3. Platform locale from [PlatformDispatcher], if supported.
/// 4. Fallback to [AppLocalizations.supportedLocales].
AppLocalizations resolveAppLocalizations({
  Locale? locale,
  BuildContext? context,
}) {
  if (locale != null) {
    return _lookupSupportedLocale(locale);
  }

  final BuildContext? resolvedContext =
      context ?? _tryCurrentNavigatorContext();
  if (resolvedContext != null) {
    final AppLocalizations? fromContext = AppLocalizations.of(resolvedContext);
    if (fromContext != null) {
      return fromContext;
    }
  }

  return _lookupSupportedLocale(PlatformDispatcher.instance.locale);
}

BuildContext? _tryCurrentNavigatorContext() {
  try {
    return globalNavigatorKey.currentContext;
  } on Object {
    // GlobalKey.currentContext throws a FlutterError when WidgetsBinding has
    // not been initialized (e.g. in headless unit tests).
    return null;
  }
}

AppLocalizations _lookupSupportedLocale(Locale locale) {
  if (AppLocalizations.delegate.isSupported(locale)) {
    return lookupAppLocalizations(locale);
  }
  final Locale languageOnly = Locale(locale.languageCode);
  if (AppLocalizations.delegate.isSupported(languageOnly)) {
    return lookupAppLocalizations(languageOnly);
  }
  return lookupAppLocalizations(AppLocalizations.supportedLocales.first);
}
