import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc responsible for fetching uncollected staking rewards.
class UncollectedStakingRewardsBloc extends FetchBloc<UncollectedReward> {
  /// Creates an [UncollectedStakingRewardsBloc].
  UncollectedStakingRewardsBloc({
    required super.zenon,
  }) : super(
         fromJsonT: UncollectedReward.fromJson,
         toJsonT: (UncollectedReward data) => data.toJson(),
       );

  @override
  Future<UncollectedReward> getData({required Address address}) =>
      zenon.embedded.stake.getUncollectedReward(address);
}
