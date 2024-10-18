
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';



part 'balance_state.dart';

/// `BalanceCubit` is responsible for managing and fetching the account balances
/// of multiple addresses. It extends the `DashboardCubit` with a state
/// represented as a `Map` of addresses and their associated `AccountInfo`.

class BalanceCubit extends DashboardCubit<AccountInfo, BalanceState> {
  /// Constructs a `BalanceCubit` with the provided `zenon` client and initial state.
  ///
  /// The [zenon] parameter provides access to the Zenon SDK for interacting with
  /// account information, and the [initialState] is a map of addresses to their
  /// respective balances at the time the cubit is initialized.
  BalanceCubit(this.address, super.zenon, super.initialState);

  final Address address;

  /// Fetches the balance information for a single address.
  ///
  /// The method interacts with the `zenon` client's ledger to get the
  /// `AccountInfo` for the provided [address].
  ///
  /// Returns an [AccountInfo] object containing the balance details for the given address.
  ///
  /// Throws an exception if the balance retrieval fails.
  @override
  Future<AccountInfo> fetch() async {
    final response = await zenon.ledger
        .getAccountInfoByAddress(address);
    if (response.blockCount! > 0 &&
        (response.znn()! > BigInt.zero || response.qsr()! > BigInt.zero)) {
      return response;
    } else {
      throw 'Empty balance on the selected address';
    }
  }
}
