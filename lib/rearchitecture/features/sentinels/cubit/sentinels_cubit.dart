import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'sentinels_cubit.g.dart';

part 'sentinels_state.dart';

/// [SentinelsCubit] manages the fetching and state of sentinel information.
///
/// It uses a [SentinelInfoList] object to represent the list of active
/// sentinels fetched from the Zenon network.
class SentinelsCubit extends TimerCubit<SentinelInfoList, SentinelsState> {
  /// Constructs a [SentinelsCubit], passing the [zenon] client and the initial
  /// state to the parent class.
  ///
  /// The [zenon] client is used to interact with the Zenon network to retrieve
  /// sentinel information.
  SentinelsCubit({
    required super.zenon,
    super.initialState = const SentinelsState(),
  });

  /// Fetches a list of active sentinels from the Zenon network.
  @override
  Future<SentinelInfoList> fetch() async {
    final SentinelInfoList data = await zenon.embedded.sentinel.getAllActive();
    return data;
  }

  @override
  SentinelsState? fromJson(Map<String, dynamic> json) =>
      SentinelsState.fromJson(
        json,
      );

  @override
  Map<String, dynamic>? toJson(SentinelsState state) => state.toJson();
}
