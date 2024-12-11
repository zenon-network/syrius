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

  /// {@macro instance_from_json}
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

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$NodeSyncStatusStateToJson(this);
}
