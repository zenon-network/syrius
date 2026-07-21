// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_not_synced_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeNotSyncedException _$NodeNotSyncedExceptionFromJson(
  Map<String, dynamic> json,
) => NodeNotSyncedException(
  message: json['message'] as String? ?? 'Node is not synced',
);

Map<String, dynamic> _$NodeNotSyncedExceptionToJson(
  NodeNotSyncedException instance,
) => <String, dynamic>{'message': instance.message};
