import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'delegation_state.dart';

/// `DelegationCubit` manages the fetching and state of delegation information
/// for a specific account.
///
/// This cubit extends `DashboardCubit<DelegationInfo>`, using the `DelegationInfo` data type
/// to store and manage delegation stats for the account identified by `kDemoAddress`.
class DelegationCubit extends DashboardCubit<DelegationInfo, DelegationState> {
  /// Constructs a `DelegationCubit`, passing the `zenon` client and the initial state
  /// to the parent class.
  ///
  /// The `zenon` client is used to interact with the Zenon network to retrieve delegation information.
  DelegationCubit(this.address, super.zenon, super.initialState);

  final Address address;

  /// Fetches the delegation information for the account identified by its address.
  ///
  /// This method retrieves delegation stats using the Zenon SDK's `getDelegatedPillar()` method.
  /// It checks if the delegation information is available:
  /// - If available, it returns the `DelegationInfo`.
  /// - If not available, it throws an error indicating that no delegation stats are available.
  ///
  /// Throws:
  /// - An error if the delegation information is unavailable or any exception occurs during data fetching.
  @override
  Future<DelegationInfo> fetch() async {
    try {
      final delegationInfo = await zenon.embedded.pillar.getDelegatedPillar(
        address,
      );

      // Check if delegation information is available
      if (delegationInfo != null) {
        return delegationInfo;
      } else {
        throw 'No delegation stats available';
      }
    } catch (e) {
      rethrow;
    }
  }
}
