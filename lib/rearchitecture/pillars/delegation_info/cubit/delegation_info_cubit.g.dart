// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delegation_info_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DelegationInfoState _$DelegationInfoStateFromJson(Map<String, dynamic> json) =>
    DelegationInfoState(
      address: json['address'] == null
          ? null
          : Address.fromJson(json['address'] as Map<String, dynamic>),
      status:
          $enumDecodeNullable(
            _$CubitWithRefreshOptionStatusEnumMap,
            json['status'],
          ) ??
          CubitWithRefreshOptionStatus.loading,
      data: json['data'] == null
          ? null
          : DelegationInfo.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DelegationInfoStateToJson(
  DelegationInfoState instance,
) => <String, dynamic>{
  'address': instance.address?.toJson(),
  'status': _$CubitWithRefreshOptionStatusEnumMap[instance.status]!,
  'data': instance.data?.toJson(),
  'error': instance.error?.toJson(),
};

const _$CubitWithRefreshOptionStatusEnumMap = {
  CubitWithRefreshOptionStatus.failure: 'failure',
  CubitWithRefreshOptionStatus.loading: 'loading',
  CubitWithRefreshOptionStatus.success: 'success',
};
