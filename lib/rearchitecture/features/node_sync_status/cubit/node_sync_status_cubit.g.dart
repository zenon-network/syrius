// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_sync_status_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeSyncStatusState _$NodeSyncStatusStateFromJson(Map<String, dynamic> json) =>
    NodeSyncStatusState(
      status: $enumDecodeNullable(_$TimerStatusEnumMap, json['status']) ??
          TimerStatus.initial,
      data: json['data'] == null
          ? null
          : Pair<SyncState, SyncInfo>.fromJson(
              json['data'] as Map<String, dynamic>,
              (value) => $enumDecode(_$SyncStateEnumMap, value),
              (value) => SyncInfo.fromJson(value as Map<String, dynamic>)),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NodeSyncStatusStateToJson(
        NodeSyncStatusState instance) =>
    <String, dynamic>{
      'status': _$TimerStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(
        (value) => _$SyncStateEnumMap[value]!,
        (value) => value.toJson(),
      ),
      'error': instance.error?.toJson(),
    };

const _$TimerStatusEnumMap = {
  TimerStatus.failure: 'failure',
  TimerStatus.initial: 'initial',
  TimerStatus.loading: 'loading',
  TimerStatus.success: 'success',
};

const _$SyncStateEnumMap = {
  SyncState.unknown: 'unknown',
  SyncState.syncing: 'syncing',
  SyncState.syncDone: 'syncDone',
  SyncState.notEnoughPeers: 'notEnoughPeers',
};
