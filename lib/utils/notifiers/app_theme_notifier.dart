import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class AppThemeNotifier extends ChangeNotifier {
  ThemeMode? _currentThemeMode = kDefaultThemeMode;

  void changeThemeMode(ThemeMode? newThemeMode) {
    if (_currentThemeMode != newThemeMode) {
      _currentThemeMode = newThemeMode;
      notifyListeners();
    }
  }

  ThemeMode? get currentThemeMode => _currentThemeMode;
}
