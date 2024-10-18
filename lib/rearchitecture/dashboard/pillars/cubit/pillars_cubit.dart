import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';

part 'pillars_state.dart';

/// `PillarsCubit` manages the fetching and state of pillar statistics.
///
/// This cubit extends `DashboardCubit<int>`, using an integer to represent the
/// total number of pillars fetched from the Zenon network.
class PillarsCubit extends DashboardCubit<int, PillarsState> {
  /// Constructs a `PillarsCubit`, passing the `zenon` client and the initial state
  /// to the parent class.
  ///
  /// The `zenon` client is used to interact with the Zenon network to retrieve pillar information.
  PillarsCubit(super.zenon, super.initialState);

  /// Fetches the total count of pillars from the Zenon network.
  ///
  /// This method retrieves all pillar information using the Zenon SDK's `getAll()` method
  /// and returns the total number of pillars as an integer.
  ///
  /// Throws:
  /// - An error if any exception occurs during the fetching of pillar data.
  @override
  Future<int> fetch() async {
    try {
      // Fetches the list of all pillars from the Zenon network
      final pillarInfoList = await zenon.embedded.pillar.getAll();
      final data = pillarInfoList.list.length; // Counts the number of pillars
      return data; // Returns the total number of pillars
    } catch (e) {
      rethrow;
    }
  }
}
