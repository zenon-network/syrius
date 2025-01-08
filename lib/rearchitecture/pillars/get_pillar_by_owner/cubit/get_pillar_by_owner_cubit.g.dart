// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_pillar_by_owner_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetPillarByOwnerState _$GetPillarByOwnerStateFromJson(
        Map<String, dynamic> json) =>
    GetPillarByOwnerState(
      address: json['address'] == null
          ? null
          : Address.fromJson(json['address'] as Map<String, dynamic>),
      status: $enumDecodeNullable(
              _$CubitWithRefreshOptionStatusEnumMap, json['status']) ??
          CubitWithRefreshOptionStatus.loading,
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
      'address': instance.address?.toJson(),
      'status': _$CubitWithRefreshOptionStatusEnumMap[instance.status]!,
      'data': instance.data?.map((e) => e.toJson()).toList(),
      'error': instance.error?.toJson(),
    };

const _$CubitWithRefreshOptionStatusEnumMap = {
  CubitWithRefreshOptionStatus.failure: 'failure',
  CubitWithRefreshOptionStatus.loading: 'loading',
  CubitWithRefreshOptionStatus.success: 'success',
};
