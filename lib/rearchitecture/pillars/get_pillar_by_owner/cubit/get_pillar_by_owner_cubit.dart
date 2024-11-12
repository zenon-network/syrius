import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubits.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'get_pillar_by_owner_cubit.g.dart';
part 'get_pillar_by_owner_state.dart';

/// A cubit responsible for fetching and managing the state
/// of pillars owned by a specific address.
class GetPillarByOwnerCubit extends CubitWithRefreshMixin<List<PillarInfo>,
    GetPillarByOwnerState> {

  /// Constructs a [GetPillarByOwnerCubit] with a [zenon] instance and the
  /// [address] for which pillar data is to be retrieved.
  GetPillarByOwnerCubit({
    required super.zenon,
    required this.address,
    bool callUpdateStream = true,
  }) : super(
    callUpdateStream: callUpdateStream,
    const GetPillarByOwnerState(),
  );

  /// The [Address] for which the cubit fetches and manages pillar data.
  final Address address;

  /// Overrides [getData] method to define how data is fetched for the cubit.
  @override
  Future<List<PillarInfo>> getData() async {
    try {
      final List<PillarInfo> response = await zenon.embedded.pillar.getByOwner(
        address,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Deserializes a JSON map into a [GetPillarByOwnerState].
  @override
  GetPillarByOwnerState? fromJson(Map<String, dynamic> json) =>
      GetPillarByOwnerState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(GetPillarByOwnerState state) =>
      state.toJson();
}
