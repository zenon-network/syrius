import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/infinite_scroll_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';

class WalletConnectSessionsBloc extends InfiniteScrollBloc<SessionData> {
  WalletConnectSessionsBloc() : super(isDataRequestPaginated: false);

  @override
  Future<List<SessionData>> getData(int pageKey, int pageSize) async {
    final wcService = sl.get<IWeb3WalletService>();
    final sessions = <SessionData>[];
    for (final pairing in wcService.pairings.value) {
      sessions.addAll(
        wcService.getSessionsForPairing(pairing.topic).values,
      );
    }
    return Future.delayed(const Duration(milliseconds: 500)).then(
      (value) => sessions,
    );
  }
}
