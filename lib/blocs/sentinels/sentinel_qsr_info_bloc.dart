import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelsQsrInfoBloc extends BaseBloc<num?> {
  Future<void> getQsrDepositedAmount(String address) async {
    try {
      addEvent(null);
      num response = (await zenon!.embedded.sentinel.getDepositedQsr(
        Address.parse(address),
      ))
          .addDecimals(
        qsrDecimals,
      );
      addEvent(response);
    } catch (e) {
      addError(e);
    }
  }
}
