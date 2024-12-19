// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_pillar_by_owner_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetPillarByOwnerState _$GetPillarByOwnerStateFromJson(
        Map<String, dynamic> json) =>
    GetPillarByOwnerState(
      status: $enumDecodeNullable(
              _$CubitWithRefreshMixinStatusEnumMap, json['status']) ??
          CubitWithRefreshMixinStatus.loading,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => PillarInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetPillarByOwnerStateToJson(
        GetPillarByOwnerState instance) =>
    <String, dynamic>{
      'status': _$CubitWithRefreshMixinStatusEnumMap[instance.status]!,
      'data': instance.data?.map((e) => e.toJson()).toList(),
      'error': instance.error?.toJson(),
    };

const _$CubitWithRefreshMixinStatusEnumMap = {
  CubitWithRefreshMixinStatus.failure: 'failure',
  CubitWithRefreshMixinStatus.loading: 'loading',
  CubitWithRefreshMixinStatus.success: 'success',
};
