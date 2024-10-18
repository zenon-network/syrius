import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'staking_state.dart';

/// `StakingCubit` manages the fetching and state of staking information.
///
/// This cubit extends `DashboardCubit<StakeList>`, using a `StakeList` object
/// to represent the list of staking entries for a specific address fetched from the Zenon network.
class StakingCubit extends DashboardCubit<StakeList, StakingState> {
  /// Constructs a `StakingCubit`, passing the `zenon` client and the initial state
  /// to the parent class.
  ///
  /// The `zenon` client is used to interact with the Zenon network to retrieve staking information.
  StakingCubit(super.zenon, super.initialState);

  /// Fetches a list of staking entries for a specific address from the Zenon network.
  ///
  /// This method retrieves the staking list by calling the internal `_getStakeList()` method.
  /// It checks if the list of stakes is not empty and returns the data.
  ///
  /// Throws:
  /// - An error if no active staking entries are found or if any exception occurs during the fetching process.
  @override
  Future<StakeList> fetch() async {
    try {
      // Retrieve the list of staking entries for the demo address
      final data = await _getStakeList();
      if (data.list.isNotEmpty) {
        return data; // Return the fetched stake data if not empty
      } else {
        throw 'No active staking entries'; // Throw an error if no entries are found
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves the staking entries for a specific address.
  ///
  /// This method fetches the staking entries by calling the Zenon SDK's `getEntriesByAddress()`
  /// method, using the account address and a specified page index.
  ///
  /// Returns:
  /// - A `StakeList` containing the staking entries for the specified address.
  Future<StakeList> _getStakeList() async {
    return zenon.embedded.stake.getEntriesByAddress(
      Address.parse(kSelectedAddress!),
    );
  }
}
