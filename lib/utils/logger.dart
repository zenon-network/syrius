import 'package:flutter/foundation.dart';

class Logger {
  static void logError(Object error) {
    if (!kReleaseMode) {
      if (error is String) {
        // ignore: avoid_print
        print('Info: $error');
      } else {
        // ignore: avoid_print
        print('Error: $error');
        if (error is Error) {
          // ignore: avoid_print
          print('Stack trace: ${error.stackTrace}');
        }
      }
    }
  }
}
