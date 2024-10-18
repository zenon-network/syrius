
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinels_state.dart';

/// `SentinelsCubit` manages the fetching and state of sentinel information.
///
/// This cubit extends `DashboardCubit<SentinelInfoList>`, using a `SentinelInfoList`
/// object to represent the list of active sentinels fetched from the Zenon network.
class SentinelsCubit extends DashboardCubit<SentinelInfoList, SentinelsState> {
  /// Constructs a `SentinelsCubit`, passing the `zenon` client and the initial state
  /// to the parent class.
  ///
  /// The `zenon` client is used to interact with the Zenon network to retrieve sentinel information.
  SentinelsCubit(super.zenon, super.initialState);

  /// Fetches a list of active sentinels from the Zenon network.
  ///
  /// This method calls the Zenon SDK's `getAllActive()` method to retrieve the list of active
  /// sentinels. The fetched data is returned as a `SentinelInfoList`.
  ///
  /// Throws:
  /// - An error if any exception occurs during the fetching process.
  @override
  Future<SentinelInfoList> fetch() async {
    try {
      // Fetches the list of all active sentinels from the Zenon network
      final data = await zenon.embedded.sentinel.getAllActive();
      return data; // Returns the fetched sentinel information
    } catch (e) {
      rethrow;
    }
  }
}

