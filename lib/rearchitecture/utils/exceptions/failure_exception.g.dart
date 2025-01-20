// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'failure_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FailureException _$FailureExceptionFromJson(Map<String, dynamic> json) =>
    FailureException(
      message: json['message'] as String? ?? 'Something went wrong',
    );

Map<String, dynamic> _$FailureExceptionToJson(FailureException instance) =>
    <String, dynamic>{
      'message': instance.message,
    };
