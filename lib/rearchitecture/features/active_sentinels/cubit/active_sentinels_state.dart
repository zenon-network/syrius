part of 'active_sentinels_cubit.dart';

/// The state class for [ActiveSentinelsCubit], which extends [TimerState] to
/// manage sentinel-related data.
///
/// This class manages a [SentinelInfoList] object representing information
/// about active sentinels. It is used to track
/// the state of sentinel data loading within the [ActiveSentinelsCubit].
@JsonSerializable(explicitToJson: true)
class ActiveSentinelsState extends TimerState<SentinelInfoList> {
  /// Constructs a new [ActiveSentinelsState] with optional values for [status],
  /// [data], and [error].
  ///
  /// The [data] field stores a [SentinelInfoList] object, which contains the
  /// details of all active sentinels on the network.
  const ActiveSentinelsState({
    super.status,
    super.data,
    super.error,
  });

  /// {@macro instance_from_json}
  factory ActiveSentinelsState.fromJson(Map<String, dynamic> json) =>
      _$ActiveSentinelsStateFromJson(json);

  /// {@macro state_copy_with}
  @override
  TimerState<SentinelInfoList> copyWith({
    TimerStatus? status,
    SentinelInfoList? data,
    SyriusException? error,
  }) {
    return ActiveSentinelsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$ActiveSentinelsStateToJson(this);
}
