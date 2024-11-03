// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_widget_balance_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransferWidgetBalanceState _$TransferWidgetBalanceStateFromJson(
        Map<String, dynamic> json) =>
    TransferWidgetBalanceState(
      status: $enumDecode(_$TransferWidgetBalanceStatusEnumMap, json['status']),
      data: (json['data'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, AccountInfo.fromJson(e as Map<String, dynamic>)),
      ),
      error: json['error'],
    );

Map<String, dynamic> _$TransferWidgetBalanceStateToJson(
        TransferWidgetBalanceState instance) =>
    <String, dynamic>{
      'status': _$TransferWidgetBalanceStatusEnumMap[instance.status]!,
      'data': instance.data?.map((k, e) => MapEntry(k, e.toJson())),
      'error': instance.error,
    };

const _$TransferWidgetBalanceStatusEnumMap = {
  TransferWidgetBalanceStatus.initial: 'initial',
  TransferWidgetBalanceStatus.loading: 'loading',
  TransferWidgetBalanceStatus.success: 'success',
  TransferWidgetBalanceStatus.failure: 'failure',
};
