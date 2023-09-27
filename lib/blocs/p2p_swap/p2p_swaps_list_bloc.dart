import 'package:zenon_syrius_wallet_flutter/blocs/p2p_swap/periodic_p2p_swap_base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/p2p_swap/p2p_swap.dart';

class P2pSwapsListBloc extends PeriodicP2pSwapBaseBloc<List<P2pSwap>> {
  @override
  List<P2pSwap> makeCall() {
    try {
      return _getSwaps();
    } catch (e) {
      rethrow;
    }
  }

  void getData() {
    try {
      final data = _getSwaps();
      addEvent(data);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }

  List<P2pSwap> _getSwaps() {
    final swaps = htlcSwapsService!.getAllSwaps();
    swaps.sort((a, b) => b.startTime.compareTo(a.startTime));
    return swaps;
  }
}
