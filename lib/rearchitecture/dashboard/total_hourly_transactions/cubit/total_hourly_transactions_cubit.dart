import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/exceptions/exceptions.dart';

part 'total_hourly_transactions_cubit.g.dart';

part 'total_hourly_transactions_state.dart';

/// `TotalHourlyTransactionsCubit` manages the fetching and state of total
/// hourly transactions.
///
/// This cubit extends `DashboardCubit<Map<String, dynamic>>`, using a map to
/// represent the total
/// number of account blocks and the corresponding timestamp fetched from the
/// Zenon network.
class TotalHourlyTransactionsCubit
    extends DashboardCubit<int, TotalHourlyTransactionsState> {
  /// Constructs a `TotalHourlyTransactionsCubit`, passing the `zenon` client
  /// and the initial state to the parent class.
  ///
  /// The `zenon` client is used to interact with the Zenon network to retrieve
  /// transaction information.

  TotalHourlyTransactionsCubit(super.zenon, super.initialState);

  /// Fetches the total number of account blocks for the last hour from the
  /// Zenon network.
  ///
  /// This method retrieves the height of the chain, checks if there are enough
  /// momentums, and fetches detailed momentums from the Zenon ledger. It
  /// calculates the total number of account blocks and prepares a map
  /// containing the number of blocks and the current timestamp.
  ///
  /// Throws:
  /// - An error if there are not enough momentums or if any exception occurs
  /// during the fetching process.
  @override
  Future<int> fetch() async {
    try {
      // Retrieve the current chain height
      final chainHeight = await _ledgerGetMomentumLedgerHeight();
      if (chainHeight - kMomentumsPerHour > 0) {
        // Fetch detailed momentums for the past hour
        final response =
            (await zenon.ledger.getDetailedMomentumsByHeight(
              chainHeight - kMomentumsPerHour,
              kMomentumsPerHour,
            ))
                .list ??
                [];

        // Prepare the transaction summary
        final transactions = response.fold<int>(
          0,
              (previousValue, element) => previousValue + element.blocks.length,
        );
        return transactions; // Return the summary of transactions
      } else {
        throw NotEnoughMomentumsException();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves the current momentum ledger height from the Zenon network.
  ///
  /// This method fetches the frontier momentum and returns its height.
  ///
  /// Returns:
  /// - An integer representing the current height of the momentum ledger.
  Future<int> _ledgerGetMomentumLedgerHeight() async {
    try {
      return (await zenon.ledger.getFrontierMomentum()).height;
    } catch (e) {
      rethrow;
    }
  }

  @override
  TotalHourlyTransactionsState? fromJson(Map<String, dynamic> json) =>
      TotalHourlyTransactionsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(TotalHourlyTransactionsState state) =>
      state.toJson();
}
