// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_transaction_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendTransactionState _$SendTransactionStateFromJson(
        Map<String, dynamic> json) =>
    SendTransactionState(
      status: $enumDecodeNullable(_$SendPaymentStatusEnumMap, json['status']) ??
          SendPaymentStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$SendTransactionStateToJson(
        SendTransactionState instance) =>
    <String, dynamic>{
      'status': _$SendPaymentStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$SendPaymentStatusEnumMap = {
  SendPaymentStatus.initial: 'initial',
  SendPaymentStatus.loading: 'loading',
  SendPaymentStatus.success: 'success',
  SendPaymentStatus.failure: 'failure',
};
