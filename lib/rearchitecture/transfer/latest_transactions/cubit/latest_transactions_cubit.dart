import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'latest_transactions_cubit.g.dart';
part 'latest_transactions_state.dart';

/// A cubit that manages the state of the latest transactions for a specific
/// [Address].
class LatestTransactionsCubit extends HydratedCubit<LatestTransactionsState> {
  /// Creates an instance of [LatestTransactionsCubit].
  ///
  /// The constructor requires a [Zenon] SDK instance and an [Address] for which
  /// the latest transactions will be fetched and managed.
  LatestTransactionsCubit({required this.zenon, required this.address})
      : super(
    const LatestTransactionsState(),
  );

  /// The [Zenon] SDK instance used for ledger interactions.
  final Zenon zenon;

  /// The [Address] whose latest transactions are being managed.
  final Address address;

  /// Fetches the latest transactions for the current [address].
  ///
  /// This method retrieves a list of [AccountBlock]s representing the latest
  /// transactions for the specified [address], using the provided [pageKey]
  /// and [pageSize] for pagination.
  /// Returns a [Future] that completes when the data fetching process is done.
  Future<void> getData(int pageKey, int pageSize) async {
    try {
      emit(state.copyWith(status: LatestTransactionsStatus.loading));

      final AccountBlockList accountBlock =
      await zenon.ledger.getAccountBlocksByPage(
        Address.parse(address.toString()),
        pageIndex: pageKey,
        pageSize: pageSize,
      );

      final List<AccountBlock> data = accountBlock.list!;

      emit(
        state.copyWith(
          status: LatestTransactionsStatus.success,
          data: data,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LatestTransactionsStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  /// Deserializes the JSON map into a [LatestTransactionsState].
  @override
  LatestTransactionsState? fromJson(Map<String, dynamic> json) =>
      LatestTransactionsState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(LatestTransactionsState state) => state.toJson();
}
