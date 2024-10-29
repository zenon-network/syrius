import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillars_cubit.g.dart';

part 'pillars_state.dart';

/// [PillarsCubit] manages the fetching and state of pillar statistics.
///
/// It uses an integer to represent the total number of pillars fetched from
/// the Zenon network.
class PillarsCubit extends TimerCubit<int, PillarsState> {
  /// Constructs a [PillarsCubit], passing the [zenon] client and the initial
  /// state to the parent class.
  ///
  /// The [zenon] client is used to interact with the Zenon network to retrieve
  /// pillar information.
  PillarsCubit({
    required super.zenon,
    super.initialState = const PillarsState(),
});

  /// Fetches the total count of pillars from the Zenon network.
  @override
  Future<int> fetch() async {
    // Fetches the list of all pillars from the Zenon network
    final PillarInfoList pillarInfoList = await zenon.embedded.pillar.getAll();
    // Counts the number of pillars
    final int data = pillarInfoList.list.length;
    return data; // Returns the total number of pillars
  }

  @override
  PillarsState? fromJson(Map<String, dynamic> json) =>
      PillarsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(PillarsState state) => state.toJson();
}
