import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/refresh_bloc_mixin.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/plasma_info_wrapper.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PlasmaStatsBloc extends BaseBloc<List<PlasmaInfoWrapper>>
    with RefreshBlocMixin {
  PlasmaStatsBloc() {
    listenToWsRestart(getPlasmas);
  }

  Future<void> getPlasmas() async {
    try {
      List<PlasmaInfoWrapper> plasmaInfoWrapper = await Future.wait(
        kDefaultAddressList.map((e) => _getPlasma(e!)).toList(),
      );
      addEvent(plasmaInfoWrapper);
    } catch (e) {
      addError(e);
    }
  }

  Future<PlasmaInfoWrapper> _getPlasma(String address) async {
    try {
      PlasmaInfo plasmaInfo = await zenon!.embedded.plasma.get(
        Address.parse(address),
      );
      return PlasmaInfoWrapper(address: address, plasmaInfo: plasmaInfo);
    } catch (e) {
      rethrow;
    }
  }
}
