import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'balance_dashboard_state.dart';

/// A `BalanceDashboardCubit` that fetches and manages the account balance data for a single account.
///
/// This cubit extends `DashboardCubit<AccountInfo>`, utilizing the `AccountInfo` data type to store
/// and manage the balance data for a specific account (identified by `kDemoAddress`).
/// It provides the logic for fetching and updating the balance.
class BalanceDashboardCubit extends DashboardCubit<AccountInfo, BalanceDashboardState> {
  /// Constructs a `BalanceDashboardCubit`, passing the `zenon` client and the initial state to the parent class.
  ///
  /// The `zenon` client is used to interact with the Zenon ledger to retrieve account information.
  BalanceDashboardCubit(super.zenon, super.initialState);

  /// Fetches the account balance data for the provided address.
  ///
  /// This method retrieves account information using the Zenon SDK's `getAccountInfoByAddress()` method.
  /// It checks the balance and block count of the account:
  /// - If the account has blocks and a non-zero balance (either ZNN or QSR), it returns the `AccountInfo`.
  /// - If the balance is empty, it throws an error indicating that the balance is zero.
  ///
  /// Throws:
  /// - An error if the balance is empty or any exception occurs during data fetching.
  @override
  Future<AccountInfo> fetch() async {
    try {
      final response = await zenon.ledger
          .getAccountInfoByAddress(Address.parse(kSelectedAddress!));

      if (response.blockCount! > 0 &&
          (response.znn()! > BigInt.zero || response.qsr()! > BigInt.zero)) {
        return response;
      } else {
        throw 'Empty balance on the selected address';
      }
    } catch (e) {
      rethrow;
    }
  }
}
