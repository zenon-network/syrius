import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pending_transactions_cubit.g.dart';
part 'pending_transactions_state.dart';

/// A cubit responsible for fetching and managing the list of pending
/// transactions for a specific [address].
class PendingTransactionsCubit extends HydratedCubit<PendingTransactionsState> {
  /// Creates a new [PendingTransactionsCubit] instance.
  ///
  /// Requires a [Zenon] instance to interact with the ledger and an [Address]
  /// for which the pending transactions are to be fetched.
  PendingTransactionsCubit({
    required this.zenon,
    required this.address,
  }) : super(const PendingTransactionsState());

  /// The instance of [Zenon] used to interact with the ledger.
  final Zenon zenon;

  /// The [Address] for which pending transactions are being managed.
  final Address address;

  /// Fetches pending transactions (unreceived blocks) for the given [address].
  ///
  /// The [pageKey] and [pageSize] parameters are used for pagination.
  Future<void> getData(int pageKey, int pageSize) async {
    try {
      emit(state.copyWith(status: PendingTransactionsStatus.loading));

      final AccountBlockList accountBlock = await zenon.ledger
          .getUnreceivedBlocksByAddress(
        address,
        pageIndex: pageKey,
        pageSize: pageSize,
      );

      final List<AccountBlock> data = accountBlock.list!;

      emit(
        state.copyWith(
          status: PendingTransactionsStatus.success,
          data: data,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PendingTransactionsStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the [PendingTransactionsState] from the provided JSON [Map].
  @override
  PendingTransactionsState? fromJson(Map<String, dynamic> json) =>
      PendingTransactionsState.fromJson(json);


  /// Serializes the current [PendingTransactionsState] into a JSON [Map].
  @override
  Map<String, dynamic>? toJson(PendingTransactionsState state) =>
      state.toJson();
}
