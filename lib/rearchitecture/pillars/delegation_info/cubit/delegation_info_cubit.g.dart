// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delegation_info_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DelegationInfoState _$DelegationInfoStateFromJson(Map<String, dynamic> json) =>
    DelegationInfoState(
      status: $enumDecodeNullable(
              _$CubitWithRefreshMixinStatusEnumMap, json['status']) ??
          CubitWithRefreshMixinStatus.loading,
      data: json['data'] == null
          ? null
          : DelegationInfo.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DelegationInfoStateToJson(
        DelegationInfoState instance) =>
    <String, dynamic>{
      'status': _$CubitWithRefreshMixinStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error?.toJson(),
    };

const _$CubitWithRefreshMixinStatusEnumMap = {
  CubitWithRefreshMixinStatus.failure: 'failure',
  CubitWithRefreshMixinStatus.loading: 'loading',
  CubitWithRefreshMixinStatus.success: 'success',
};
