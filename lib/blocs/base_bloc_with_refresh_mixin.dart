import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/refresh_bloc_mixin.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

abstract class BaseBlocWithRefreshMixin<T> extends BaseBloc<T>
    with RefreshBlocMixin {
  Future<T> getDataAsync();

  BaseBlocWithRefreshMixin() {
    updateStream();
    listenToWsRestart(updateStream);
  }

  Future<void> updateStream() async {
    try {
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
