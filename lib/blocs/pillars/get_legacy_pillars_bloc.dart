import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class GetLegacyPillarsBloc extends BaseBloc<List<SwapLegacyPillarEntry>?> {
  Future<void> checkForLegacyPillar() async {
    try {
      addEvent(null);
      addEvent(await zenon!.embedded.swap.getLegacyPillars());
    } catch (e) {
      addError(e);
    }
  }
}
