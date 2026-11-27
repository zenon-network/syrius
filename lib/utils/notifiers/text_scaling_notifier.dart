import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_display/model/display_settings_enums.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

/// Notifies listeners when the application's [TextScaling] preference changes.
class TextScalingNotifier extends ChangeNotifier {
  TextScaling? _currentTextScaling = kDefaultTextScaling;

  /// Updates the active text scaling mode to [newTextScaling] and notifies
  /// listeners if it changed.
  void changeTextScaling(TextScaling? newTextScaling) {
    if (_currentTextScaling != newTextScaling) {
      _currentTextScaling = newTextScaling;
      notifyListeners();
    }
  }

  /// Resolves the numeric text scale factor for the current [TextScaling]
  /// setting using [context]'s media query when set to [TextScaling.system].
  double getTextScaleFactor(BuildContext context) {
    switch (_currentTextScaling) {
      case TextScaling.system:
        return MediaQuery.of(context).textScaler.scale(1);
      case TextScaling.normal:
        return 1;
      case TextScaling.small:
        return 0.8;
      case TextScaling.large:
        return 1.5;
      case TextScaling.huge:
        return 2;
      case null:
        return 1;
    }
  }

  /// Currently active [TextScaling] preference.
  TextScaling? get currentTextScaling => _currentTextScaling;
}
