// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'no_delegation_stats_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoDelegationStatsException _$NoDelegationStatsExceptionFromJson(
        Map<String, dynamic> json) =>
    NoDelegationStatsException(
      message: json['message'] as String? ?? 'No delegation stats available',
    );

Map<String, dynamic> _$NoDelegationStatsExceptionToJson(
        NoDelegationStatsException instance) =>
    <String, dynamic>{
      'message': instance.message,
    };
