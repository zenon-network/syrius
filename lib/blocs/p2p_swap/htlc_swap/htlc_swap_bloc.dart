import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/periodic_p2p_swap_base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/htlc_swap.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class HtlcSwapBloc extends PeriodicP2pSwapBaseBloc<HtlcSwap> {
  final String swapId;

  HtlcSwapBloc(this.swapId);

  @override
  HtlcSwap makeCall() {
    try {
      if (zenon!.wsClient.isClosed()) {
        throw noConnectionException;
      }
      final swap = htlcSwapsService!.getSwapById(swapId);
      if (swap != null) {
        return swap;
      } else {
        throw 'Swap does not exist';
      }
    } catch (e) {
      rethrow;
    }
  }
}
