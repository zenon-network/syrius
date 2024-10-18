import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

abstract class DashboardBaseBloc<T> extends BaseBloc<T> with RefreshBlocMixin {

  DashboardBaseBloc() {
    listenToWsRestart(getDataPeriodically);
  }
  Timer? _autoRefresher;

  Future<T> makeAsyncCall();

  Timer _getAutoRefreshTimer() => Timer(
        kIntervalBetweenMomentums,
        () {
          _autoRefresher!.cancel();
          getDataPeriodically();
        },
      );

  Future<void> getDataPeriodically() async {
    try {
      if (!zenon!.wsClient.isClosed()) {
        final data = await makeAsyncCall();
        addEvent(data);
      } else {
        throw noConnectionException;
      }
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    } finally {
      if (_autoRefresher == null) {
        _autoRefresher = _getAutoRefreshTimer();
      } else if (!_autoRefresher!.isActive) {
        _autoRefresher = _getAutoRefreshTimer();
      }
    }
  }

  @override
  void dispose() {
    _autoRefresher?.cancel();
    super.dispose();
  }
}
