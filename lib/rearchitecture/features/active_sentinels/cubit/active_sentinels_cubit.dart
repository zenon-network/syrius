import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'active_sentinels_cubit.g.dart';

part 'active_sentinels_state.dart';

/// [ActiveSentinelsCubit] manages active sentinel summary information.
///
/// It uses a [SentinelInfoList] object to represent the list of active
/// sentinels fetched from the Zenon network.
class ActiveSentinelsCubit
    extends TimerCubit<SentinelInfoList, ActiveSentinelsState> {
  /// Constructs an [ActiveSentinelsCubit], passing the [zenon] client and the
  /// initial state to the parent class.
  ///
  /// The [zenon] client is used to interact with the Zenon network to retrieve
  /// sentinel information.
  ActiveSentinelsCubit({
    required super.zenon,
    super.initialState = const ActiveSentinelsState(),
  });

  /// Fetches a list of active sentinels from the Zenon network.
  @override
  Future<SentinelInfoList> fetch() async {
    final SentinelInfoList data = await zenon.embedded.sentinel.getAllActive();
    return data;
  }

  @override
  ActiveSentinelsState? fromJson(Map<String, dynamic> json) =>
      ActiveSentinelsState.fromJson(
        json,
      );

  @override
  Map<String, dynamic>? toJson(ActiveSentinelsState state) => state.toJson();
}
