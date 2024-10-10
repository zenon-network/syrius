
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';



part 'balance_state.dart';

/// `BalanceCubit` is responsible for managing and fetching the account balances
/// of multiple addresses. It extends the `DashboardCubit` with a state
/// represented as a `Map` of addresses and their associated `AccountInfo`.

class BalanceCubit extends DashboardCubit<Map<String, AccountInfo>> {
  /// Constructs a `BalanceCubit` with the provided `zenon` client and initial state.
  ///
  /// The [zenon] parameter provides access to the Zenon SDK for interacting with
  /// account information, and the [initialState] is a map of addresses to their
  /// respective balances at the time the cubit is initialized.
  BalanceCubit(super.zenon, super.initialState);

  /// Fetches the balance information for a list of predefined addresses.
  ///
  /// This method retrieves the account information for each address in the
  /// `kDefaultAddressList`, and stores it in a map where the key is the
  /// address string, and the value is the `AccountInfo` for that address.
  ///
  /// If an error occurs during the fetch operation, it will be propagated upwards.
  ///
  /// Returns a [Map] where each key is an address and the corresponding value is
  /// an [AccountInfo] object for that address.
  @override
  Future<Map<String, AccountInfo>> fetch() async {
    try {
      final Map<String, AccountInfo> addressBalanceMap = {};
      final List<AccountInfo> accountInfoList = await Future.wait(
        kDefaultAddressList.map(
              (address) => _getBalancePerAddress(address!),
        ),
      );

      for (var accountInfo in accountInfoList) {
        addressBalanceMap[accountInfo.address!] = accountInfo;
      }

      return addressBalanceMap;
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves the balance information for a single address.
  ///
  /// The method interacts with the `zenon` client's ledger to get the
  /// `AccountInfo` for the provided [address]. The address is parsed from
  /// a string into an `Address` object before querying the ledger.
  ///
  /// Returns an [AccountInfo] object containing the balance details for the given address.
  ///
  /// Throws an exception if the balance retrieval fails.
  Future<AccountInfo> _getBalancePerAddress(String address) async {
    return await zenon.ledger.getAccountInfoByAddress(Address.parse(address));
  }
}
