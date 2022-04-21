import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc_with_refresh_mixin.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/general_stats.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class GeneralStatsBloc extends BaseBlocWithRefreshMixin<GeneralStats> {
  Timer? _timer;

  @override
  Future<GeneralStats> getDataAsync() async {
    GeneralStats _generalStats = GeneralStats(
        frontierMomentum: await zenon!.ledger.getFrontierMomentum(),
        processInfo: await zenon!.stats.processInfo(),
        networkInfo: await zenon!.stats.networkInfo(),
        osInfo: await zenon!.stats.osInfo());
    if (_timer == null || !_timer!.isActive) {
      _timer = _getTimer();
    }
    return _generalStats;
  }

  @override
  dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Timer _getTimer() => Timer(
        kIntervalBetweenMomentums,
        () {
          _timer?.cancel();
          updateStream();
        },
      );
}
