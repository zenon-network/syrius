import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_receive_tx_worker.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'receive_transaction_cubit.g.dart';

part 'receive_transaction_state.dart';

/// A cubit responsible for handling the reception of transactions.
///
/// This cubit uses an [AutoReceiveTxWorker] to automatically receive a
/// transaction given its [id].
class ReceiveTransactionCubit extends HydratedCubit<ReceiveTransactionState> {
  /// Creates a new [ReceiveTransactionCubit] instance.
  ///
  /// Requires an [AutoReceiveTxWorker] to process the transactions.
  ReceiveTransactionCubit(this.autoReceiveTxWorker)
      : super(const ReceiveTransactionState());

  /// The worker responsible for automatically receiving transactions.
  final AutoReceiveTxWorker autoReceiveTxWorker;

  /// Receives a transaction with the given [id].
  ///
  /// The [context] is used for any UI interactions or navigation if necessary.
  Future<void> receiveTransaction(String id, BuildContext context) async {
    try {
      emit(state.copyWith(status: ReceiveTransactionStatus.loading));

      final AccountBlockTemplate? response =
      await autoReceiveTxWorker.autoReceiveTransactionHash(Hash.parse(id));

      emit(
        state.copyWith(
          status: ReceiveTransactionStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ReceiveTransactionStatus.failure,
          error: e,
        ),
      );
    }
  }


    /// Deserializes the [ReceiveTransactionState] from the provided JSON [Map].
    @override
    ReceiveTransactionState? fromJson(Map<String, dynamic> json) =>
        ReceiveTransactionState.fromJson(json);


    /// Serializes the current [ReceiveTransactionState] into a JSON [Map].
    @override
    Map<String, dynamic>? toJson(ReceiveTransactionState state) =>
        state.toJson();
  }
