// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_sync_status_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeSyncStatusState _$NodeSyncStatusStateFromJson(Map<String, dynamic> json) =>
    NodeSyncStatusState(
      status: $enumDecodeNullable(_$DashboardStatusEnumMap, json['status']) ??
          DashboardStatus.initial,
      data: json['data'] == null
          ? null
          : Pair<SyncState, SyncInfo>.fromJson(
              json['data'] as Map<String, dynamic>,
              (value) => $enumDecode(_$SyncStateEnumMap, value),
              (value) => SyncInfo.fromJson(value as Map<String, dynamic>)),
      error: json['error'],
    );

Map<String, dynamic> _$NodeSyncStatusStateToJson(
        NodeSyncStatusState instance) =>
    <String, dynamic>{
      'status': _$DashboardStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(
        (value) => _$SyncStateEnumMap[value]!,
        (value) => value,
      ),
      'error': instance.error,
    };

const _$DashboardStatusEnumMap = {
  DashboardStatus.failure: 'failure',
  DashboardStatus.initial: 'initial',
  DashboardStatus.loading: 'loading',
  DashboardStatus.success: 'success',
};

const _$SyncStateEnumMap = {
  SyncState.unknown: 'unknown',
  SyncState.syncing: 'syncing',
  SyncState.syncDone: 'syncDone',
  SyncState.notEnoughPeers: 'notEnoughPeers',
};
