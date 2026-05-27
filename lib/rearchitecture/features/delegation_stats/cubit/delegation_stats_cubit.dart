import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'delegation_stats_cubit.g.dart';

part 'delegation_stats_state.dart';

/// A cubit that manages the fetching and state of delegation stats information
/// for a specific account.
class DelegationStatsCubit extends TimerCubit<DelegationInfo, DelegationStatsState> {
  /// Constructs a DelegationCubit object, passing the [zenon] client and the
  /// initial state to the parent class.
  ///
  /// The [zenon] client is used to interact with the Zenon network to retrieve
  /// delegation stats information.
  DelegationStatsCubit({
    required this.address,
    required super.zenon,
    super.initialState = const DelegationStatsState(),
  });

  /// The address for which the [DelegationInfo] will be fetched
  final Address address;

  /// Fetches the delegation stats information for the account identified by its
  /// address.
  ///
  /// This method retrieves delegation stats stats
  /// It checks if the delegation stats information is available:
  /// - If available, it returns the [DelegationInfo].
  /// - If not available, it throws an exception
  @override
  Future<DelegationInfo> fetch() async {
    final DelegationInfo? delegationInfo =
        await zenon.embedded.pillar.getDelegatedPillar(
      address,
    );

    // Check if delegation stats information is available
    if (delegationInfo != null) {
      return delegationInfo;
    } else {
      throw NoDelegationStatsException();
    }
  }

  @override
  DelegationStatsState? fromJson(Map<String, dynamic> json) =>
      DelegationStatsState.fromJson(
        json,
      );

  @override
  Map<String, dynamic>? toJson(DelegationStatsState state) => state.toJson();
}
