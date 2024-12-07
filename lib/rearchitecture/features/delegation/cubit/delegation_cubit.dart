import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'delegation_cubit.g.dart';

part 'delegation_state.dart';

/// A cubit that manages the fetching and state of delegation information
/// for a specific account.
class DelegationCubit extends TimerCubit<DelegationInfo, DelegationState> {
  /// Constructs a DelegationCubit object, passing the [zenon] client and the
  /// initial state to the parent class.
  ///
  /// The [zenon] client is used to interact with the Zenon network to retrieve
  /// delegation information.
  DelegationCubit({
    required this.address,
    required super.zenon,
    super.initialState = const DelegationState(),
  });

  /// The address for which the [DelegationInfo] will be fetched
  final Address address;

  /// Fetches the delegation information for the account identified by its
  /// address.
  ///
  /// This method retrieves delegation stats
  /// It checks if the delegation information is available:
  /// - If available, it returns the [DelegationInfo].
  /// - If not available, it throws an exception
  @override
  Future<DelegationInfo> fetch() async {
    final DelegationInfo? delegationInfo =
        await zenon.embedded.pillar.getDelegatedPillar(
      address,
    );

    // Check if delegation information is available
    if (delegationInfo != null) {
      return delegationInfo;
    } else {
      throw NoDelegationStatsException();
    }
  }

  @override
  DelegationState? fromJson(Map<String, dynamic> json) =>
      DelegationState.fromJson(
        json,
      );

  @override
  Map<String, dynamic>? toJson(DelegationState state) => state.toJson();
}
