import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';

class WalletConnectPairingsBloc extends BaseBloc<List<PairingInfo>?> {
  Future<void> getPairings() async {
    try {
      addEvent(null);
      final pairings = sl.get<WalletConnectService>().getPairings().getAll();
      if (pairings.isNotEmpty) {
        addEvent(pairings);
      } else {
        addError('s y r i u s is not paired with any dApp', null);
      }
    } catch (e, stackTrace) {
      addError(error, stackTrace);
    }
  }
}
