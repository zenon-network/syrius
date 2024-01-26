import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ReceiveTransactionBloc extends BaseBloc<AccountBlockTemplate?> {
  void receiveTransaction(String id, BuildContext context) {
    try {
      addEvent(null);
      sl<AutoReceiveTxWorker>().autoReceiveTransactionHash(Hash.parse(id))
      .onError(
        (error, stackTrace) {
          addError(error, stackTrace);
        },
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}