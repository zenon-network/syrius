part of 'sentinels_cubit.dart';

/// The state class for [SentinelsCubit], which extends [TimerState] to
/// manage sentinel-related data.
///
/// This class manages a [SentinelInfoList] object representing information
/// about active sentinels. It is used to track
/// the state of sentinel data loading within the [SentinelsCubit].
@JsonSerializable()
class SentinelsState extends TimerState<SentinelInfoList> {
  /// Constructs a new [SentinelsState] with optional values for [status],
  /// [data], and [error].
  ///
  /// The [data] field stores a [SentinelInfoList] object, which contains the
  /// details of all active sentinels on the network.
  const SentinelsState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a [SentinelsState] instance from a JSON map.
  factory SentinelsState.fromJson(Map<String, dynamic> json) =>
      _$SentinelsStateFromJson(json);

  /// Creates a copy of the current [SentinelsState] with updated values for
  /// [status], [data], or [error] if provided, otherwise retaining the
  /// existing values.
  @override
  TimerState<SentinelInfoList> copyWith({
    TimerStatus? status,
    SentinelInfoList? data,
    SyriusException? error,
  }) {
    return SentinelsState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// Converts this [SentinelsState] instance to a JSON map.
  Map<String, dynamic> toJson() => _$SentinelsStateToJson(this);
}