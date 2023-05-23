import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/infinite_scroll_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';

class WalletConnectPairingsBloc extends InfiniteScrollBloc<PairingInfo> {
  WalletConnectPairingsBloc() : super(isDataRequestPaginated: false);

  @override
  Future<List<PairingInfo>> getData(int pageKey, int pageSize) =>
      Future.delayed(const Duration(milliseconds: 500)).then(
        (value) => sl.get<WalletConnectService>().pairings,
      );
}
