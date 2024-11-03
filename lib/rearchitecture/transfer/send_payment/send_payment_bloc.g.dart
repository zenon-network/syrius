// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_payment_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendPaymentState _$SendPaymentStateFromJson(Map<String, dynamic> json) =>
    SendPaymentState(
      status: $enumDecode(_$SendPaymentStatusEnumMap, json['status']),
      data: json['data'] == null
          ? null
          : AccountBlockTemplate.fromJson(json['data'] as Map<String, dynamic>),
      error: json['error'],
    );

Map<String, dynamic> _$SendPaymentStateToJson(SendPaymentState instance) =>
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
