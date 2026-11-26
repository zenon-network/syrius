import 'dart:async';
import 'dart:ui';

import 'package:zenon_syrius_wallet_flutter/main.dart';

/// Mixin that subscribes a BLoC to Zenon WebSocket reconnect events so it can
/// refresh stale data after a connection restart.
mixin RefreshBlocMixin {
  StreamSubscription<bool>? _restartWsStreamSubscription;

  /// Subscribes to [restartedStream] (defaulting to
  /// `zenon?.wsClient.restartedStream`) and invokes
  /// [onWsConnectionRestartedCallback] whenever a reconnect succeeds (`true`).
  ///
  /// Any previous subscription is cancelled before registering the new one.
  void listenToWsRestart(
    VoidCallback onWsConnectionRestartedCallback, {
    Stream<bool>? restartedStream,
  }) {
    unawaited(_restartWsStreamSubscription?.cancel());
    _restartWsStreamSubscription = null;

    final Stream<bool>? stream =
        restartedStream ?? zenon?.wsClient.restartedStream;
    if (stream == null) {
      return;
    }

    _restartWsStreamSubscription = stream.listen(
      (bool restarted) {
        if (restarted) {
          onWsConnectionRestartedCallback();
        }
      },
    );
  }

  /// Cancels the active WebSocket restart subscription, if any.
  Future<void> cancelStreamSubscription() async {
    final StreamSubscription<bool>? subscription = _restartWsStreamSubscription;
    _restartWsStreamSubscription = null;
    await subscription?.cancel();
  }
}
