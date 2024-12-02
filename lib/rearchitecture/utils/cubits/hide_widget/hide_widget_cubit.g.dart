// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hide_widget_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HideWidgetState _$HideWidgetStateFromJson(Map<String, dynamic> json) =>
    HideWidgetState(
      status: $enumDecode(_$HideWidgetStatusEnumMap, json['status']),
      exception: json['exception'] == null
          ? null
          : SyriusException.fromJson(json['exception'] as Map<String, dynamic>),
      isHidden: json['isHidden'] as bool?,
    );

Map<String, dynamic> _$HideWidgetStateToJson(HideWidgetState instance) =>
    <String, dynamic>{
      'exception': instance.exception,
      'isHidden': instance.isHidden,
      'status': _$HideWidgetStatusEnumMap[instance.status]!,
    };

const _$HideWidgetStatusEnumMap = {
  HideWidgetStatus.failure: 'failure',
  HideWidgetStatus.initial: 'initial',
  HideWidgetStatus.loading: 'loading',
  HideWidgetStatus.success: 'success',
};
