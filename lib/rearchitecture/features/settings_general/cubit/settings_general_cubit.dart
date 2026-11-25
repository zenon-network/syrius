import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_general/model/settings_general_data.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'settings_general_cubit.g.dart';
part 'settings_general_state.dart';

/// Periodically fetches general momentum and peer statistics for Settings.
class SettingsGeneralCubit
    extends TimerCubit<SettingsGeneralData, SettingsGeneralState> {
  /// Creates a [SettingsGeneralCubit].
  SettingsGeneralCubit({
    required super.zenon,
    super.initialState = const SettingsGeneralState(),
    super.refreshInterval = kIntervalBetweenMomentums,
  });

  @override
  Future<SettingsGeneralData> fetch() async {
    final Momentum frontierMomentum = await zenon.ledger.getFrontierMomentum();
    final NetworkInfo networkInfo = await zenon.stats.networkInfo();

    return SettingsGeneralData(
      momentumHeight: frontierMomentum.height,
      momentumTimestamp: frontierMomentum.timestamp,
      momentumHash: frontierMomentum.hash.toString(),
      peerCount: networkInfo.peers.length,
    );
  }

  @override
  SettingsGeneralState? fromJson(Map<String, dynamic> json) =>
      SettingsGeneralState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(SettingsGeneralState state) => state.toJson();
}
