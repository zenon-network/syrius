import 'package:flutter/material.dart';

/// Notifies listeners to refresh plasma statistics widgets.
class PlasmaGeneratedNotifier extends ChangeNotifier {
  /// Triggers a rebuild of listening plasma stats widgets.
  void rebuildPlasmaStatsWidget() {
    notifyListeners();
  }
}
