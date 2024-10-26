part of 'node_sync_status_cubit.dart';

/// Class used by [NodeSyncStatusCubit] to send state updates to the
/// connected view
@JsonSerializable()
class NodeSyncStatusState extends DashboardState<Pair<SyncState, SyncInfo>> {
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
  DashboardState<Pair<SyncState, SyncInfo>> copyWith({
    DashboardStatus? status,
    Pair<SyncState, SyncInfo>? data,
    Object? error,
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
