import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'dual_coin_stats_state.dart';

/// `DualCoinStatsCubit` manages the fetching and state of dual coin statistics
/// for ZNN and QSR tokens.
///
/// This cubit extends [DashboardCubit], using a list of `Token` objects to
/// represent the statistics for the ZNN and QSR tokens fetched from the Zenon network.
class DualCoinStatsCubit extends DashboardCubit<List<Token>, DualCoinStatsState> {
  /// Constructs a `DualCoinStatsCubit`, passing the `zenon` client and the initial state
  /// to the parent class.
  ///
  /// The `zenon` client is used to interact with the Zenon network to retrieve token information.
  DualCoinStatsCubit(super.zenon, super.initialState);

  /// Fetches the statistics for both ZNN and QSR tokens.
  ///
  /// This method retrieves token data using the Zenon SDK's `getByZts()` method for each token,
  /// executing the requests concurrently using `Future.wait()`. It returns a list containing
  /// the fetched token data for ZNN and QSR.
  ///
  /// Throws:
  /// - An error if any exception occurs during the fetching of token data.
  @override
  Future<List<Token>> fetch() async {
    try {
      final data = await Future.wait(
        [
          zenon.embedded.token.getByZts(
            znnZts, // Fetches the ZNN token statistics
          ),
          zenon.embedded.token.getByZts(
            qsrZts, // Fetches the QSR token statistics
          ),
        ],
      );

      // For ZNN and QSR, the network will return non-nullable data
      final nonNullableData = data.map((token) => token!).toList();

      // The list has only two elements
      return nonNullableData;
    } catch (e) {
      rethrow;
    }
  }
}
