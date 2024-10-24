part of 'node_sync_status_cubit.dart';

/// Class used by [NodeSyncStatusCubit] to send state updates to the
/// connected view
class NodeSyncStatusState extends DashboardState<Pair<SyncState, SyncInfo>> {

  const NodeSyncStatusState({
    super.status,
    super.data,
    super.error,
  });

  @override
  DashboardState<Pair<SyncState, SyncInfo>> copyWith({
    CubitStatus? status,
    Pair<SyncState, SyncInfo>? data,
    Object? error,
  }) {
    return NodeSyncStatusState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}
