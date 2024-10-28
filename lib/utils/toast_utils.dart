import 'dart:async';

import 'package:flutter/material.dart';

class ToastUtils {
  static Timer? _timer;

  static void showToast(BuildContext context, String message, {Color? color}) {
    if (_timer == null || !_timer!.isActive) {
      final OverlayEntry overlay = _getOverlayEntry(message, color);
      Overlay.of(context).insert(overlay);
      _timer = Timer(const Duration(seconds: 3), overlay.remove);
    }
  }

  static OverlayEntry _getOverlayEntry(String message, Color? color) {
    return OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 0, end: 1),
        builder: (_, double opacity, __) {
          return Opacity(
            opacity: opacity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Container(
                alignment: Alignment.bottomCenter,
                child: Material(
                  elevation: 6,
                  color: color,
                  surfaceTintColor: Colors.black,
                  borderRadius: BorderRadius.circular(50),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
