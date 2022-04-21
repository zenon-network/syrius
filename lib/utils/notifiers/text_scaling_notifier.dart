import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/settings_widgets/display.dart';

class TextScalingNotifier extends ChangeNotifier {
  TextScaling? _currentTextScaling = kDefaultTextScaling;

  void changeTextScaling(TextScaling? newTextScaling) {
    if (_currentTextScaling != newTextScaling) {
      _currentTextScaling = newTextScaling;
      notifyListeners();
    }
  }

  getTextScaleFactor(BuildContext context) {
    switch (_currentTextScaling) {
      case TextScaling.system:
        return MediaQuery.of(context).textScaleFactor;
      case TextScaling.normal:
        return 1.0;
      case TextScaling.small:
        return 0.8;
      case TextScaling.large:
        return 1.5;
      case TextScaling.huge:
        return 2.0;
      case null:
        return 1.0;
    }
  }

  get currentTextScaling => _currentTextScaling;
}
