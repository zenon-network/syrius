import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'total_hourly_transactions_cubit.g.dart';

part 'total_hourly_transactions_state.dart';

/// [TotalHourlyTransactionsCubit] manages the fetching and state of total
/// hourly transactions.
class TotalHourlyTransactionsCubit
    extends TimerCubit<int, TotalHourlyTransactionsState> {
  /// Constructs a [TotalHourlyTransactionsCubit], passing the [zenon] client
  /// and the initial state to the parent class.
  ///
  /// The [zenon] client is used to interact with the Zenon network to retrieve
  /// transaction information.
  TotalHourlyTransactionsCubit({
    required super.zenon,
    super.initialState = const TotalHourlyTransactionsState(),
  });

  /// Fetches the total number of account blocks for the last hour from the
  /// Zenon network.
  ///
  /// This method retrieves the height of the chain, checks if there are enough
  /// momentums, and fetches detailed momentums from the Zenon ledger. It
  /// calculates then the total number of account blocks
  ///
  /// Throws:
  /// - An error if there are not enough momentums or if any exception occurs
  /// during the fetching process.
  @override
  Future<int> fetch() async {
    // Retrieve the current chain height
    final int chainHeight = await _ledgerGetMomentumLedgerHeight();
    if (chainHeight - kMomentumsPerHour > 0) {
      // Fetch detailed momentums for the past hour
      final List<DetailedMomentum> response =
          (await zenon.ledger.getDetailedMomentumsByHeight(
                chainHeight - kMomentumsPerHour,
                kMomentumsPerHour,
              ))
                  .list ??
              <DetailedMomentum>[];

      // Prepare the transaction summary
      final int transactions = response.fold<int>(
        0,
        (int previousValue, DetailedMomentum element) =>
            previousValue + element.blocks.length,
      );
      return transactions; // Return the summary of transactions
    } else {
      throw NotEnoughMomentumsException();
    }
  }

  /// Retrieves the current momentum ledger height from the Zenon network.
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
