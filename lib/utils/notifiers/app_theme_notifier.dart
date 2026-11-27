import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

/// Notifies listeners when the application's [ThemeMode] changes.
class AppThemeNotifier extends ChangeNotifier {
  ThemeMode? _currentThemeMode = kDefaultThemeMode;

  /// Updates the active theme mode to [newThemeMode] and notifies listeners if
  /// it changed.
  void changeThemeMode(ThemeMode? newThemeMode) {
    if (_currentThemeMode != newThemeMode) {
      _currentThemeMode = newThemeMode;
      notifyListeners();
    }
  }

  /// Currently active [ThemeMode].
  ThemeMode? get currentThemeMode => _currentThemeMode;
}
