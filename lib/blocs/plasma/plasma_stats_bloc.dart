import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PlasmaStatsBloc extends BaseBloc<List<PlasmaInfoWrapper>>
    with RefreshBlocMixin {
  PlasmaStatsBloc() {
    listenToWsRestart(getPlasmas);
  }

  Future<void> getPlasmas() async {
    try {
      final plasmaInfoWrapper = await Future.wait(
        kDefaultAddressList.map((e) => _getPlasma(e!)).toList(),
      );
      addEvent(plasmaInfoWrapper);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }

  Future<PlasmaInfoWrapper> _getPlasma(String address) async {
    try {
      final plasmaInfo = await zenon!.embedded.plasma.get(
        Address.parse(address),
      );
      return PlasmaInfoWrapper(address: address, plasmaInfo: plasmaInfo);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
      rethrow;
    }
  }
}
