// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receive_transaction_cubit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiveTransactionState _$ReceiveTransactionStateFromJson(
        Map<String, dynamic> json) =>
    ReceiveTransactionState(
      status: $enumDecodeNullable(
              _$ReceiveTransactionStatusEnumMap, json['status']) ??
          ReceiveTransactionStatus.initial,
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$ReceiveTransactionStateToJson(
        ReceiveTransactionState instance) =>
    <String, dynamic>{
      'status': _$ReceiveTransactionStatusEnumMap[instance.status]!,
      'data': instance.data?.toJson(),
      'error': instance.error,
    };

const _$ReceiveTransactionStatusEnumMap = {
  ReceiveTransactionStatus.initial: 'initial',
  ReceiveTransactionStatus.loading: 'loading',
  ReceiveTransactionStatus.failure: 'failure',
  ReceiveTransactionStatus.success: 'success',
};
