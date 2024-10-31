part of 'realtime_statistics_cubit.dart';

/// The state class for [RealtimeStatisticsCubit], which extends
/// [TimerState] to handle real-time statistics data.
///
/// This class manages a list of [AccountBlock] objects representing real-time
/// blockchain data, such as recent transactions.
/// It's used to track the state of the data loading process in the
/// [RealtimeStatisticsCubit].
@JsonSerializable(explicitToJson: true)
class RealtimeStatisticsState extends TimerState<List<AccountBlock>> {
  /// Constructs a new [RealtimeStatisticsState] with optional values for
  /// [status], [data], and [error].
  ///
  /// The [data] field stores a list of [AccountBlock] objects that represent
  /// real-time blockchain statistics.
  const RealtimeStatisticsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a [RealtimeStatisticsState] instance from a JSON map.
  factory RealtimeStatisticsState.fromJson(Map<String, dynamic> json) =>
      _$RealtimeStatisticsStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  TimerState<List<AccountBlock>> copyWith({
    TimerStatus? status,
    List<AccountBlock>? data,
    SyriusException? error,
  }) {
    return RealtimeStatisticsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// Converts this [RealtimeStatisticsState] instance to a JSON map.
  Map<String, dynamic> toJson() => _$RealtimeStatisticsStateToJson(this);
}
