import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc responsible for fetching and managing the state of
/// uncollected sentinel rewards for a specific address.
class UncollectedSentinelRewardsBloc extends FetchBloc<UncollectedReward> {
  /// {@macro default_constructor}
  UncollectedSentinelRewardsBloc({
    required super.zenon,
  }) : super(
          fromJsonT: UncollectedReward.fromJson,
          toJsonT: (UncollectedReward data) => data.toJson(),
        );

  @override
  Future<UncollectedReward> getData({required Address address}) =>
      zenon.embedded.sentinel.getUncollectedReward(address);
}
