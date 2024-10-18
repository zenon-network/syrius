import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/sentinels_qsr_info.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelsQsrInfoBloc extends BaseBloc<SentinelsQsrInfo?> {
  Future<void> getQsrManagementInfo(String address) async {
    try {
      addEvent(null);
      final deposit = await zenon!.embedded.sentinel.getDepositedQsr(
        Address.parse(address),
      );
      final cost = sentinelRegisterQsrAmount;
      addEvent(
        SentinelsQsrInfo(
          deposit: deposit,
          cost: cost,
        ),
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
