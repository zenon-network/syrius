import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'latest_transactions_cubit.g.dart';
part 'latest_transactions_state.dart';

class LatestTransactionsCubit extends Cubit<LatestTransactionsState> {

  LatestTransactionsCubit(this.zenon)
      : super(const LatestTransactionsState(
    status: LatestTransactionsStatus.initial,
    ),
  );

  final Zenon zenon;

  Future<void> getData(int pageKey, int pageSize) async {
    try {
      emit(state.copyWith(status: LatestTransactionsStatus.loading));

      final AccountBlockList accountBlock =
        await zenon.ledger.getAccountBlocksByPage(
          Address.parse(emptyAddress.toString()),
          pageIndex: pageKey,
          pageSize: pageSize,
      );

      final List<AccountBlock> data = accountBlock.list!;

      emit(state.copyWith(
        status: LatestTransactionsStatus.success,
        data: data,
      ),
      );
    } catch (e) {
      emit(state.copyWith(status: LatestTransactionsStatus.failure, error: e));
    }
  }

  @override
  LatestTransactionsState? fromJson(Map<String, dynamic> json) =>
      LatestTransactionsState.fromJson(
        json,
  );

  @override
  Map<String, dynamic>? toJson(LatestTransactionsState state) => state.toJson();
}
