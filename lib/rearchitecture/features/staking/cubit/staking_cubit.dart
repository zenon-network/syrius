import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'staking_cubit.g.dart';

part 'staking_state.dart';

/// [StakingCubit] manages the fetching and state of staking information.
///
/// It uses a [StakeList] object to represent the list of staking entries for a
/// specific address.
class StakingCubit extends TimerCubit<StakeList, StakingState> {
  /// Constructs a [StakingCubit], passing the [zenon] client and the initial
  /// state to the parent class.
  ///
  /// The [zenon] client is used to interact with the Zenon network to retrieve
  /// staking information.
  StakingCubit(super.zenon, super.initialState);

  /// Fetches a list of staking entries for a specific address from the Zenon
  /// network.
  ///
  /// Throws:
  /// - An error if no active staking entries are found or if any exception
  /// occurs during the fetching process.
  @override
  Future<StakeList> fetch() async {
    // Retrieve the list of staking entries for the demo address
    final StakeList data = await _getStakeList();
    if (data.list.isNotEmpty) {
      return data; // Return the fetched stake data if not empty
    } else {
      throw NoActiveStakingEntriesException();
    }
  }
  // TODO(maznnwell): replace the global kSelectedAddress variable
  /// Retrieves the staking entries for a specific address.
  Future<StakeList> _getStakeList() async {
    return zenon.embedded.stake.getEntriesByAddress(
      Address.parse(kSelectedAddress!),
    );
  }

  @override
  StakingState? fromJson(Map<String, dynamic> json) => StakingState.fromJson(
        json,
      );

  @override
  Map<String, dynamic>? toJson(StakingState state) => state.toJson();
}
