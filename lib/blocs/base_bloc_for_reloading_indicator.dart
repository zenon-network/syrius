import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

abstract class BaseBlocForReloadingIndicator<T> extends BaseBloc<T?>
    with RefreshBlocMixin {
  Future<T> getDataAsync();

  BaseBlocForReloadingIndicator() {
    updateStream();
    listenToWsRestart(updateStream);
  }

  Future<void> updateStream() async {
    try {
      addEvent(null);
      if (!zenon!.wsClient.isClosed()) {
        addEvent(await getDataAsync());
      } else {
        throw noConnectionException;
      }
    } catch (e) {
      addError(e);
    }
  }

  @override
  dispose() {
    cancelStreamSubscription();
    super.dispose();
  }
}
