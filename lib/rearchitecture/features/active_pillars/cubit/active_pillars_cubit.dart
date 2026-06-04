import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'active_pillars_cubit.g.dart';

part 'active_pillars_state.dart';

/// [ActivePillarsCubit] manages the fetching and state of pillar statistics.
///
/// It uses an integer to represent the total number of active_pillars fetched
/// from the Zenon network.
class ActivePillarsCubit extends TimerCubit<int, ActivePillarsState> {
  /// Constructs a [ActivePillarsCubit], passing the [zenon] client and the
  /// initial state to the parent class.
  ///
  /// The [zenon] client is used to interact with the Zenon network to retrieve
  /// pillar information.
  ActivePillarsCubit({
    required super.zenon,
    super.initialState = const ActivePillarsState(),
  });

  /// Fetches the total count of active_pillars from the Zenon network.
  @override
  Future<int> fetch() async {
    final PillarInfoList pillarInfoList = await zenon.embedded.pillar.getAll();
    final int data = pillarInfoList.list.length;
    kNumOfPillars = data;
    return data;
  }

  @override
  ActivePillarsState? fromJson(Map<String, dynamic> json) =>
      ActivePillarsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(ActivePillarsState state) => state.toJson();
}
