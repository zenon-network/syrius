// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'undelegate_button_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UndelegateButtonState _$UndelegateButtonStateFromJson(
        Map<String, dynamic> json) =>
    UndelegateButtonState(
      status: $enumDecodeNullable(
              _$UndelegateButtonStatusEnumMap, json['status']) ??
          UndelegateButtonStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$UndelegateButtonStateToJson(
        UndelegateButtonState instance) =>
    <String, dynamic>{
      'status': _$UndelegateButtonStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$UndelegateButtonStatusEnumMap = {
  UndelegateButtonStatus.initial: 'initial',
  UndelegateButtonStatus.loading: 'loading',
  UndelegateButtonStatus.failure: 'failure',
  UndelegateButtonStatus.success: 'success',
};
