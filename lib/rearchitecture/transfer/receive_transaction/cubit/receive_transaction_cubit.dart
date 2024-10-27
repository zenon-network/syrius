import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_receive_tx_worker.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'receive_transaction_state.dart';

class ReceiveTransactionCubit extends Cubit<ReceiveTransactionState> {

  ReceiveTransactionCubit(this.zenon, this.autoReceiveTxWorker)
      : super(const ReceiveTransactionState(
    status: ReceiveTransactionStatus.initial,
  ),
  );

  final Zenon zenon;
  final AutoReceiveTxWorker autoReceiveTxWorker;

  Future<void> receiveTransaction(String id, BuildContext context) async {
    try {
      emit(state.copyWith(status: ReceiveTransactionStatus.loading));

      final response = await autoReceiveTxWorker
          .autoReceiveTransactionHash(Hash.parse(id));

      emit(state.copyWith(
        status: ReceiveTransactionStatus.success,
        data: response,
      ),
      );
    } catch (e) {
      emit(state.copyWith(status: ReceiveTransactionStatus.failure, error: e));
    }
  }
}
