import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PlasmaListBloc extends InfiniteScrollBloc<FusionEntry> {
  int? lastMomentumHeight;

  @override
  Future<List<FusionEntry>> getData(int pageKey, int pageSize) async {
    final results =
        (await zenon!.embedded.plasma.getEntriesByAddress(
      Address.parse(kSelectedAddress!),
      pageIndex: pageKey,
      pageSize: pageSize,
    ))
            .list;
    final lastMomentum = await zenon!.ledger.getFrontierMomentum();
    lastMomentumHeight = lastMomentum.height;
    for (final fusionEntry in results) {
      fusionEntry.isRevocable =
          lastMomentum.height > fusionEntry.expirationHeight;
    }
    return results;
  }
}
