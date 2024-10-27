import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'balance_cubit.g.dart';
part 'balance_state.dart';

/// A cubit that is responsible for managing and fetching the account balance
/// of the provided [address].

class BalanceCubit extends TimerCubit<AccountInfo, BalanceState> {
  /// Constructs a BalanceCubit with the provided [zenon] client, [address] and
  /// [initialState].
  BalanceCubit(this.address, super.zenon, super.initialState);

  /// The address for which the balance will be retrieved
  final Address address;

  /// Fetches the balance information for a single address.
  ///
  /// The method interacts with the `zenon` client's ledger to get the
  /// `AccountInfo` for the provided [address].
  ///
  /// Returns an [AccountInfo] object containing the balance details for the
  /// given address.
  ///
  /// Throws an exception if the balance retrieval fails.
  @override
  Future<AccountInfo> fetch() async {
    final response = await zenon.ledger.getAccountInfoByAddress(address);
    if (response.blockCount! > 0 &&
        (response.znn()! > BigInt.zero || response.qsr()! > BigInt.zero)) {
      return response;
    } else {
      throw NoBalanceException();
    }
  }

  @override
  BalanceState? fromJson(Map<String, dynamic> json) => BalanceState.fromJson(
        json,
      );

  @override
  Map<String, dynamic>? toJson(BalanceState state) => state.toJson();
}
