import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class TextScalingNotifier extends ChangeNotifier {
  TextScaling? _currentTextScaling = kDefaultTextScaling;

  void changeTextScaling(TextScaling? newTextScaling) {
    if (_currentTextScaling != newTextScaling) {
      _currentTextScaling = newTextScaling;
      notifyListeners();
    }
  }

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

  TextScaling? get currentTextScaling => _currentTextScaling;
}
