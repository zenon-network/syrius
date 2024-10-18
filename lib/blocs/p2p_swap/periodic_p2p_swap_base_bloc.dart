import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';

abstract class PeriodicP2pSwapBaseBloc<T> extends BaseBloc<T> {
  final _refreshInterval = const Duration(seconds: 5);

  Timer? _autoRefresher;

  T makeCall();

  void getDataPeriodically() {
    try {
      final data = makeCall();
      addEvent(data);
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

  Timer _getAutoRefreshTimer() => Timer(
        _refreshInterval,
        () {
          _autoRefresher!.cancel();
          getDataPeriodically();
        },
      );

  @override
  void dispose() {
    _autoRefresher?.cancel();
    super.dispose();
  }
}
