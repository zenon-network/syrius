import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/delegation_stats/delegation_stats.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Fetches delegation statistics for an address.
class DelegationStatsBloc extends FetchBloc<DelegationInfo> {
  /// Creates a delegation stats bloc.
  DelegationStatsBloc({required super.zenon})
    : super(
        fromJsonT: DelegationInfo.fromJson,
        toJsonT: (DelegationInfo data) => data.toJson(),
      );

  @override
  Future<DelegationInfo> getData({required Address address}) async {
    final DelegationInfo? delegationInfo = await zenon.embedded.pillar
        .getDelegatedPillar(
          address,
        );

    // Check if delegation stats information is available
    if (delegationInfo != null) {
      return delegationInfo;
    } else {
      throw NoDelegationStatsException();
    }
  }
}
