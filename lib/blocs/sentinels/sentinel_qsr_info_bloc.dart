import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelsQsrInfoBloc extends BaseBloc<BigInt?> {
  Future<void> getQsrDepositedAmount(String address) async {
    try {
      addEvent(null);
      BigInt response = await zenon!.embedded.sentinel.getDepositedQsr(
        Address.parse(address),
      );
      addEvent(response);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
