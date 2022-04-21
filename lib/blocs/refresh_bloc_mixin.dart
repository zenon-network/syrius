import 'dart:async';
import 'dart:ui';

import 'package:zenon_syrius_wallet_flutter/main.dart';

mixin RefreshBlocMixin {
  StreamSubscription? _restartWsStreamSubscription;

  void listenToWsRestart(VoidCallback onWsConnectionRestartedCallback) {
    _restartWsStreamSubscription = zenon!.wsClient.restartedStream.listen(
      (restarted) {
        if (restarted) {
          onWsConnectionRestartedCallback();
        }
      },
    );
  }

  void cancelStreamSubscription() {
    _restartWsStreamSubscription?.cancel();
  }
}
