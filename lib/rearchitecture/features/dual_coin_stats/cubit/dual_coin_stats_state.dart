part of 'dual_coin_stats_cubit.dart';

/// The state class for the [DualCoinStatsCubit], extending [TimerState] to
/// manage data related to ZNN and QSR.
///
/// [DualCoinStatsState] stores a list of [Token] objects representing data
/// for two tokens.
/// This state is used by the [DualCoinStatsCubit] to track and update the
/// state of both tokens.
@JsonSerializable()
class DualCoinStatsState extends TimerState<List<Token>> {
  /// Constructs a new [DualCoinStatsState].
  ///
  /// This state is initialized with default [status], [data], and [error]
  /// values from the parent [TimerState] class.
  /// It manages a list of [Token] objects that represent the two coins' data.
  const DualCoinStatsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a [DualCoinStatsState] instance from a JSON map.
  factory DualCoinStatsState.fromJson(Map<String, dynamic> json) =>
      _$DualCoinStatsStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  TimerState<List<Token>> copyWith({
    TimerStatus? status,
    List<Token>? data,
    CubitException? error,
  }) {
    return DualCoinStatsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// Converts this [DualCoinStatsState] instance to a JSON map.
  Map<String, dynamic> toJson() => _$DualCoinStatsStateToJson(this);
}
