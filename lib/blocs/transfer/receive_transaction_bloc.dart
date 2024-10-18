import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ReceiveTransactionBloc extends BaseBloc<AccountBlockTemplate?> {
  Future<void> receiveTransaction(String id, BuildContext context) async {
    try {
      addEvent(null);
      final response = await sl<AutoReceiveTxWorker>()
          .autoReceiveTransactionHash(Hash.parse(id));
      addEvent(response);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
