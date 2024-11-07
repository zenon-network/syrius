// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delegate_button_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DelegateButtonState _$DelegateButtonStateFromJson(Map<String, dynamic> json) =>
    DelegateButtonState(
      status:
          $enumDecodeNullable(_$DelegateButtonStatusEnumMap, json['status']) ??
              DelegateButtonStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$DelegateButtonStateToJson(
        DelegateButtonState instance) =>
    <String, dynamic>{
      'status': _$DelegateButtonStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$DelegateButtonStatusEnumMap = {
  DelegateButtonStatus.initial: 'initial',
  DelegateButtonStatus.loading: 'loading',
  DelegateButtonStatus.failure: 'failure',
  DelegateButtonStatus.success: 'success',
};
