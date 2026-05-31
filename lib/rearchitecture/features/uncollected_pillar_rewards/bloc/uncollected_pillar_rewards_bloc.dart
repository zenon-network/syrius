import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc responsible for fetching and managing the state of
/// uncollected rewards for a specific address.
class UncollectedPillarRewards extends FetchBloc<UncollectedReward> {
  /// {@macro default_constructor}
  UncollectedPillarRewards({
    required super.zenon,
  }) : super(
         fromJsonT: UncollectedReward.fromJson,
         toJsonT: (UncollectedReward data) => data.toJson(),
       );

  @override
  Future<UncollectedReward> getData({required Address address}) =>
      zenon.embedded.pillar.getUncollectedReward(address);
}
