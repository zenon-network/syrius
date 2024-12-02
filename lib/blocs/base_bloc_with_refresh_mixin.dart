import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

abstract class BaseBlocWithRefreshMixin<T> extends BaseBloc<T>
    with RefreshBlocMixin {

  BaseBlocWithRefreshMixin() {
    updateStream();
    listenToWsRestart(updateStream);
  }
  Future<T> getDataAsync();

  Future<void> updateStream() async {
    try {
      if (!zenon!.wsClient.isClosed()) {
        addEvent(await getDataAsync());
      } else {
        throw noConnectionException;
      }
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }

  @override
  dispose() {
    cancelStreamSubscription();
    super.dispose();
  }
}
