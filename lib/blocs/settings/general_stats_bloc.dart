import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class GeneralStatsBloc extends BaseBlocWithRefreshMixin<GeneralStats> {
  Timer? _timer;

  @override
  Future<GeneralStats> getDataAsync() async {
    final generalStats = GeneralStats(
        frontierMomentum: await zenon!.ledger.getFrontierMomentum(),
        processInfo: await zenon!.stats.processInfo(),
        networkInfo: await zenon!.stats.networkInfo(),
        osInfo: await zenon!.stats.osInfo(),);
    if (_timer == null || !_timer!.isActive) {
      _timer = _getTimer();
    }
    return generalStats;
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
