import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pending_transactions_state.dart';


class PendingTransactionsCubit extends Cubit<PendingTransactionsState> {

  PendingTransactionsCubit(this.zenon)
      : super(const PendingTransactionsState(
    status: PendingTransactionsStatus.initial,
  ),
  );

  final Zenon zenon;

  Future<void> getData(int pageKey, int pageSize) async {
    try {
      emit(state.copyWith(status: PendingTransactionsStatus.loading));

      final accountBlock = await zenon.ledger.getUnreceivedBlocksByAddress(
        Address.parse('kDemoAddress'),
        pageIndex: pageKey,
        pageSize: pageSize,
      );

      final data = accountBlock.list!;

      emit(state.copyWith(
          status: PendingTransactionsStatus.success,
          data: data,
      ),
      );
    } catch (e) {
      emit(state.copyWith(status: PendingTransactionsStatus.failure, error: e));
    }
  }
}
