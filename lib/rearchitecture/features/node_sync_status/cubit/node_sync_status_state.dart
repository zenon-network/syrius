part of 'node_sync_status_cubit.dart';

/// Class used by [NodeSyncStatusCubit] to send state updates to the
/// connected view
@JsonSerializable(explicitToJson: true)
class NodeSyncStatusState extends TimerState<Pair<SyncState, SyncInfo>> {
  /// Creates a NodeSyncStatusState object.
  const NodeSyncStatusState({
    super.status,
    super.data,
    super.error,
  });

  /// Creates a [NodeSyncStatusState] instance from a JSON map.
  factory NodeSyncStatusState.fromJson(Map<String, dynamic> json) =>
      _$NodeSyncStatusStateFromJson(json);

  @override
  TimerState<Pair<SyncState, SyncInfo>> copyWith({
    TimerStatus? status,
    Pair<SyncState, SyncInfo>? data,
    SyriusException? error,
  }) {
    return NodeSyncStatusState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// Converts this [NodeSyncStatusState] instance to a JSON map.
  Map<String, dynamic> toJson() => _$NodeSyncStatusStateToJson(this);
}
