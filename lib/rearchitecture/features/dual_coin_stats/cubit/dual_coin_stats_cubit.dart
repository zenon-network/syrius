import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'dual_coin_stats_cubit.g.dart';

part 'dual_coin_stats_state.dart';

/// A cubit that manages the fetching and state of dual coin statistics
/// for ZNN and QSR tokens.
///
/// This cubit extends [TimerCubit], using a list of [Token] objects to
/// represent the statistics for the ZNN and QSR tokens fetched from the Zenon
/// network.
class DualCoinStatsCubit
    extends TimerCubit<List<Token>, DualCoinStatsState> {
  /// Constructs a [DualCoinStatsCubit], passing the [zenon] client and the
  /// initial state to the parent class.
  ///
  /// The [zenon] client is used to interact with the Zenon network to retrieve
  /// token information.
  DualCoinStatsCubit(super.zenon, super.initialState);

  /// Fetches the statistics for both ZNN and QSR tokens.
  ///
  /// It returns a list containing the fetched token data for ZNN and QSR.
  @override
  Future<List<Token>> fetch() async {
    final data = await Future.wait(
      [
        zenon.embedded.token.getByZts(
          znnZts, // Fetches the ZNN token statistics
        ),
        zenon.embedded.token.getByZts(
          qsrZts, // Fetches the QSR token statistics
        ),
      ],
    );

    // For ZNN and QSR, the network will return non-nullable data
    final nonNullableData = data.map((token) => token!).toList();

    return nonNullableData;
  }

  @override
  DualCoinStatsState? fromJson(Map<String, dynamic> json) =>
      DualCoinStatsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(DualCoinStatsState state) => state.toJson();
}
