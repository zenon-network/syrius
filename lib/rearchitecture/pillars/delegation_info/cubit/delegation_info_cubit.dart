import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubits.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'delegation_info_cubit.g.dart';
part 'delegation_info_state.dart';

/// A cubit that manages the state of delegation information
/// for a specific address.
class DelegationInfoCubit
    extends CubitWithRefreshMixin<DelegationInfo?, DelegationInfoState> {

  /// Constructs a [DelegationInfoCubit].
  ///
  /// The parameters are a [Zenon] instance,
  /// an [address] for which delegation data is to be retrieved,
  DelegationInfoCubit({
    required super.zenon,
    required this.address,
  }) : super(
    initialState: const DelegationInfoState(),
  );

  /// The [address] for which the cubit fetches and manages delegation data.
  final Address address;

  /// Fetches the delegation information for the specified [address].
  @override
  Future<DelegationInfo?> getData() async {
    try {
      final DelegationInfo? response =
      await zenon.embedded.pillar.getDelegatedPillar(
        address,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Deserializes a JSON map into a [DelegationInfoState] instance.
  @override
  DelegationInfoState? fromJson(Map<String, dynamic> json) =>
      DelegationInfoState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(DelegationInfoState state) => state.toJson();
}
